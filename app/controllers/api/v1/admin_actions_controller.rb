class Api::V1::AdminActionsController < ApplicationController
    before_action :set_card, only: [:disable_custom_giftcard]
    before_action :authenticate_admin!

		def index
			begin
				fx_rate = Fx.where('name = ?', fx_params[:name])
				raise ExceptionHandler::DataType, "you can not create a duplicate entry for fx_rate" if fx_rate.exists?
				raise ExceptionHandler::DataType, "please supply rate and exchange_rate values" if fx_params[:rate].blank? || fx_params[:exchange_rate].blank?
		

				fx_rate =	Fx.create!(fx_params)


					previous_rate = fx_rate.rate
					previous_exchange_rate = fx_rate.exchange_rate


					FxHistory.create!(
						admin: current_admin, fx: fx_rate, 
						current_rate: fx_params[:rate], 
						previous_rate: previous_rate,
						previous_exchange_rate: previous_exchange_rate,
						current_exchange_rate: fx_params[:exchange_rate]
				)
					json_response({
							status: 200,
							data: nil,
							message: "fx_rate created",
							errMessage: nil
					})
			rescue => e
					raise ExceptionHandler::RegularError, e
			end
	
		end



    def fetch
			fx_rate = []
			Fx.find_each do |fx|
				fx_rate << fx
			end
	
			json_response({
				status: 200,
				data: {
					fx_rate: fx_rate
				},
				message: "current fx_rate on the platform",
				errMessage: nil
			})
    end


      def update
        begin
            raise ExceptionHandler::DataType, "please supply rate and exchange_rate values" if fx_params[:rate].blank? || fx_params[:exchange_rate].blank?
            fx_rate = Fx.find_by!('id = ?', params[:fx_id])
            previous_rate = fx_rate.rate
            previous_exchange_rate = fx_rate.exchange_rate
            fx_rate.update!(fx_params)
            FxHistory.create!(
                admin: current_admin, fx: fx_rate, 
                current_rate: fx_params[:rate] || previous_rate, 
                previous_rate: previous_rate,
                previous_exchange_rate: previous_exchange_rate,
                current_exchange_rate: fx_params[:exchange_rate] || previous_exchange_rate
            )
            json_response({
                status: 200,
                data: nil,
                message: "fx_rate updated",
                errMessage: nil
            })
        rescue => e
            raise ExceptionHandler::RegularError, e
        end

      end
    
      def transactions_index

        begin

          transactions = TransactionLog.order('created_at DESC').page params[:page]



          if !params[:per_page].blank?
            transactions = TransactionLog.order('created_at DESC').page(params[:page]).per(params[:per_page])
          end
      
          total = TransactionLog.count
          page_count = transactions.total_pages  
          per_page = transactions.limit_value 
          current_page = transactions.current_page
          next_page = transactions.next_page
          prev_page = transactions.prev_page
          first_page = transactions.first_page?
          last_page = transactions.last_page?
  
  
          response.headers['total'] = total
          response.headers['page_count'] = page_count
          response.headers['per_page'] = per_page
          response.headers['current_page'] = current_page
          response.headers['next_page'] = next_page
          response.headers['prev_page'] = prev_page
          response.headers['first_page'] = first_page
          response.headers['last_page'] = last_page

        json_response({
          status: 200,
          data: {
            total: total,
            page_count: page_count,
            per_page: per_page,
            current_page: current_page,
            next_page: next_page,
            prev_page: prev_page,
            first_page: first_page,
            last_page: last_page,
            data: ActiveModelSerializers::SerializableResource.new(transactions, each_serializer: AdminTransactionsSerializer)
          },
          message: "Transactions",
          errMessage: nil
        })
        rescue => exception
          json_response({
            status: 500,
            data: nil,
            message: "Error",
            errMessage: e.message || "Oops, can't fetch giftcards at this time"
            }, :internal_server_error)
        end
        
      end

      def send_admin_invite_email

        begin
            invite = AdminInvite.where("created_at >= ? AND email = ?", (Time.current - 604800), send_invite_params[:email])
        # binding.pry
            if invite.exists?
                invite = AdminInvite.find_by(email: send_invite_params[:email])
                if ENV['RAILS_ENV'] != 'production'
                    AdminMailer.admin_invite(send_invite_params[:email], @current_admin, invite.code).deliver
                else
                    AdminMailer.admin_invite(send_invite_params[:email], @current_admin, invite.code).deliver_later
                end
            else
              
                admin = Admin.where(email: send_invite_params[:email])
                raise ExceptionHandler::RegularError, "This email is aleady used by an admin user" if admin.exists?


                AdminInvite.where("created_at < ? AND email = ?", (Time.current - 604800), send_invite_params[:email]).destroy_all
                reference = generate_ref_id

                AdminInvite.create!(code: reference, email: send_invite_params[:email], role: send_invite_params[:role], admin: @current_admin)

                if ENV['RAILS_ENV'] != 'production'
                  AdminMailer.admin_invite(send_invite_params[:email], @current_admin, reference).deliver
                else
                  AdminMailer.admin_invite(send_invite_params[:email], @current_admin, reference).deliver_later
                end
            end

            json_response({
                status: 200,
                data: nil,
                message: "admin invite sent",
                errMessage: nil
            })
        rescue Exception => e
            raise ExceptionHandler::RegularError, e
        end
      end

      def verify_admin_invite_email
        begin
          # invite = AdminInvite.where(code: verify_invite_params[:invite_code])
          invite = AdminInvite.where("created_at >= ? AND code = ?", (Time.current - 604800), verify_invite_params[:invite_code])

          if invite.exists?
            invite = AdminInvite.find_by(code: verify_invite_params[:invite_code])
            invite.update(is_verified: true)
            json_response({
                status: 200,
                data: {
                    invitee: ActiveModelSerializers::SerializableResource.new(invite, each_serializer: AdminInviteeSerializer)
                },
                message: "invite verified",
                errMessage: nil
            })
          else
            raise ExceptionHandler::InvalidToken, "your invite token does not exist/has already been confirm! please request a new invite from admin"
          end
         
        rescue Exception => e
          raise ExceptionHandler::RegularError, e
        end
      end


      def get_invite_roles
        json_response({
            status: 200,
            data: {
                roles: [
                    {
                        title: "Admin",
                        value: "admin",
                        is_active: true
                    },
					          {
                        title: "Finance",
                        value: "finance",
                        is_active: true
				            }
                ]
            },
            message: 'these are the available roles',
            errMessage: nil
        })
    end

      def customers_index
        customers = Profile.order('first_name ASC').page params[:page]

        if !params[:per_page].blank?
          customers = Profile.order('first_name ASC').page(params[:page]).per(params[:per_page])
        end
  
        total = Profile.count
        page_count = customers.total_pages 
        per_page = customers.limit_value 
        current_page = customers.current_page
        next_page = customers.next_page
        prev_page = customers.prev_page
        first_page = customers.first_page?
        last_page = customers.last_page?


        response.headers['total'] = total
        response.headers['page_count'] = page_count
        response.headers['per_page'] = per_page
        response.headers['current_page'] = current_page
        response.headers['next_page'] = next_page
        response.headers['prev_page'] = prev_page
        response.headers['first_page'] = first_page
        response.headers['last_page'] = last_page


        json_response({
          status: 200,
          data: {
            total: total,
            page_count: page_count,
            per_page: per_page,
            current_page: current_page,
            next_page: next_page,
            prev_page: prev_page,
            first_page: first_page,
            last_page: last_page,
            data: ActiveModelSerializers::SerializableResource.new(customers, each_serializer: CustomerSerializer)
          },
          message: "customers",
          errMessage: nil
        })
      end



      def users_index
        users = Admin.order('email ASC').page params[:page]

        if !params[:per_page].blank?
          users = Admin.order('email ASC').page(params[:page]).per(params[:per_page])
        end
  
        total = Admin.count
        page_count = users.total_pages 
        per_page = users.limit_value 
        current_page = users.current_page
        next_page = users.next_page
        prev_page = users.prev_page
        first_page = users.first_page?
        last_page = users.last_page?


        response.headers['total'] = total
        response.headers['page_count'] = page_count
        response.headers['per_page'] = per_page
        response.headers['current_page'] = current_page
        response.headers['next_page'] = next_page
        response.headers['prev_page'] = prev_page
        response.headers['first_page'] = first_page
        response.headers['last_page'] = last_page


        json_response({
          status: 200,
          data: {
            total: total,
            page_count: page_count,
            per_page: per_page,
            current_page: current_page,
            next_page: next_page,
            prev_page: prev_page,
            first_page: first_page,
            last_page: last_page,
            data: ActiveModelSerializers::SerializableResource.new(users, each_serializer: AdminSerializer)
          },
          message: "customers",
          errMessage: nil
        })
      end

      def fetch_fx_history
        # rates = FxHistory.
        rates_log = FxHistory.order('created_at DESC').page params[:page]


        if !params[:per_page].blank?
          rates_log = FxHistory.order('created_at DESC').page(params[:page]).per(params[:per_page])
        end

        total = FxHistory.count
        page_count = rates_log.total_pages
        per_page = rates_log.limit_value 
        current_page = rates_log.current_page
        next_page = rates_log.next_page
        prev_page = rates_log.prev_page
        first_page = rates_log.first_page?
        last_page = rates_log.last_page?


        response.headers['total'] = total
        response.headers['page_count'] = page_count
        response.headers['per_page'] = per_page
        response.headers['current_page'] = current_page
        response.headers['next_page'] = next_page
        response.headers['prev_page'] = prev_page
        response.headers['first_page'] = first_page
        response.headers['last_page'] = last_page



          json_response({
            status: 200,
            data: {
              total: total,
              page_count: page_count,
              per_page: per_page,
              current_page: current_page,
              next_page: next_page,
              prev_page: prev_page,
              first_page: first_page,
              last_page: last_page,
              data: ActiveModelSerializers::SerializableResource.new(rates_log, each_serializer: FxHistorySerializer)
            },
            message: "Fx History",
            errMessage: nil
          })
      end




      
      def custom_giftcard_index
        begin
          @custom_cards = []
          CustomGiftCard.find_each do |card|
            @custom_cards << card if card.try(:is_active)
          end
    
    
    
          if !params[:per_page].blank?
            @custom_cards = Kaminari.paginate_array(@custom_cards.sort!{ |a,b|   a.caption <=> b.caption }).page(params[:page]).per(params[:per_page])
          else
            @custom_cards = Kaminari.paginate_array(@custom_cards.sort!{ |a,b|   a.caption <=> b.caption }).page(params[:page])
          end
    
          total = @custom_cards.total_count
          page_count = @custom_cards.total_pages  
          per_page = @custom_cards.limit_value 
          current_page = @custom_cards.current_page
          next_page = @custom_cards.next_page
          prev_page = @custom_cards.prev_page
          first_page = @custom_cards.first_page?
          last_page = @custom_cards.last_page?
    
        
      
          json_response({
            status: 200,
            data: {
              total: total,
              page_count: page_count,
              per_page: per_page,
              current_page: current_page,
              next_page: next_page,
              prev_page: prev_page,
              first_page: first_page,
              last_page: last_page,
              data: ActiveModelSerializers::SerializableResource.new(@custom_cards, each_serializer: CustomGiftCardSerializer)
            },
            message: "available gift cards",
            errMessage: nil
          })
        rescue Exception => e
          raise(ExceptionHandler::RegularError, e)
        end
       
    end
    
    def disable_custom_giftcard
      begin

        values = nil
        values = params[:data][:values] if params.try(:[], :data) && params.try(:[], :data).try(:[], :values)
        if !values.nil? && values.kind_of?(String)
          values = JSON.parse(params[:data][:values])
        end
        @custom_card.update!(custom_card_params)
  
        if params.try(:[], :data) && params.try(:[], :data).try(:[], :values)
          @custom_card.update!({values: values})
        end
       
        json_response({
          status: 200,
          data: nil,
          message: "gift card updated",
          errMessage: nil
        })
      rescue => e
        raise ExceptionHandler::RegularError, e
      end
    end


    def set_vendor_giftcard_source
      begin

        vendor_id = params[:data][:id] 
        raise ExceptionHandler::RegularError, "please supply vendor id" if vendor_id.blank?

        sources = nil
        sources = params[:data][:sources] if params.try(:[], :data) && params.try(:[], :data).try(:[], :sources)

        raise ExceptionHandler::RegularError, "please supply giftcard source " if sources.blank?
        raise ExceptionHandler::RegularError, "please sources cannot have an empty value" if sources.any? { |source| source.blank? }

        if !sources.nil? && sources.kind_of?(String)
          sources = JSON.parse(params[:data][:sources])
        end

       vendor = Vendor.find(vendor_id)
       vendor.update!({is_authorised: true})
       vendor_allowed_giftcard_source = VendorAllowedGiftcardSource.where(vendor_id: vendor.id)
       raise ExceptionHandler::RegularError, "This is a duplicate action, you can't create multiple allowed giftcard sources for the same vendor" if vendor_allowed_giftcard_source.exists?
        
       VendorAllowedGiftcardSource.create!({sources: sources, created_by_id: @current_admin.id, vendor_id: vendor.id})

        json_response({
          status: 200,
          data: nil,
          message: "vendor giftcard source created",
          errMessage: nil
        })
      rescue => e
        raise ExceptionHandler::RegularError, e
      end
    end

    def update_vendor_giftcard_source
      begin
        vendor_allowed_source_is_active = nil
        vendor_id = params[:data][:id] 
        vendor_is_authorised = params[:data][:is_authorised] 
        vendor_allowed_source_is_active = params[:data][:is_active]
        raise ExceptionHandler::RegularError, "please supply vendor id" if vendor_id.blank?

        sources = nil
        sources = params[:data][:sources] if params.try(:[], :data) && params.try(:[], :data).try(:[], :sources)

        raise ExceptionHandler::RegularError, "please supply giftcard source " if sources.blank?
        raise ExceptionHandler::RegularError, "please sources cannot have an empty value" if sources.any? { |source| source.blank? }

        if !sources.nil? && sources.kind_of?(String)
          sources = JSON.parse(params[:data][:sources])
        end

       vendor = Vendor.find(vendor_id)

       
       if !vendor_is_authorised.nil?
        vendor.update!({ is_authorised: vendor_is_authorised }) 
       end
        
       vendor_allowed_giftcard_source = VendorAllowedGiftcardSource.find_by!(vendor_id: vendor.id)

       vendor_allowed_giftcard_source.update!({sources: sources, created_by_id: @current_admin.id, vendor_id: vendor.id, is_active: vendor_allowed_source_is_active })

        json_response({
          status: 200,
          data: nil,
          message: "vendor giftcard source update",
          errMessage: nil
        })
      rescue => e
        raise ExceptionHandler::RegularError, e
      end
    end


    private

    def fx_params
        params.require(:data).permit(
          :name, 
          :currency, :currency_symbol, 
          :iso, :rate, 
          :exchange_rate, :is_active, 
          :is_public
        )
    end
  
    def custom_card_params
      # whitelist params
      params.require(:data).permit(
        :caption,
        :color,
        :desc,
        :disclosures,
        :discount,
        :fontcolor,
        :max_range,
        :min_range,
        :logo,
        :is_disabled,
        :is_active
      )
    end

    def set_card
      unless params[:code].blank?
        if params[:code].include?("dcg")
          @custom_card = CustomGiftCard.find_by(code: params[:code])
        else
          @custom_card = CustomGiftCard.find(params[:code])
        end
      end
    end
  
    def send_invite_params
      params.require(:data).permit(:email, :role)
    end

    def verify_invite_params
      params.permit(:invite_code)
    end
end
