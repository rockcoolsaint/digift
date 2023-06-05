class Api::V1::CartActionsController < ApplicationController
    before_action :authenticate_user!
    before_action :validate_personal_user!

    def index
        cart = Cart.find_by(profile: @current_user.profiles.first.id, checked_out: false, is_active: true)
        if !Cart.where(profile: @current_user.profiles.first.id, checked_out: false, is_active: true).exists?
            cart = Cart.create(profile: @current_user.profiles.first)
        end
        json_response({
            status: 200,
            data: {
                cart: ActiveModelSerializers::SerializableResource.new(cart, each_serializer: CartSerializer) 
            },
            message: "current cart",
            errMessage: nil
        })
    end

    def add_cart_item
        begin
			raise ExceptionHandler::RegularError, "cart_id is missing from params" if params[:cart_id].blank?
			cart = Cart.where(id: params[:cart_id], checked_out: false, is_active: true)
			raise ExceptionHandler::RegularError, "could not find cart" unless cart.exists?

			CartItem.create!(cart_id: params[:cart_id], value: cart_item_params[:value], quantity: cart_item_params[:quantity], card_code: cart_item_params[:card_code])

			json_response({
					status: 200,
					data: nil,
					message: "item added to cart",
					errMessage: nil
			})
        rescue ActiveRecord::RecordInvalid => e
            raise ExceptionHandler::RegularError, e
        end
    end

		def update_cart_item
			begin
				raise ExceptionHandler::RegularError, "cart_id is missing from params" if params[:cart_id].blank?
				raise ExceptionHandler::RegularError, "cart_item_id is missing from params" if params[:cart_item_id].blank?


				cart = Cart.where(id: params[:cart_id], checked_out: false, is_active: true)
				raise ExceptionHandler::RegularError, "could not find cart" unless cart.exists?

				cart_item = CartItem.where(id: params[:cart_item_id], checked_out: false, is_active: true)
				raise ExceptionHandler::RegularError, "could not find cart item" unless cart_item.exists?

				raise ExceptionHandler::RegularError, "quantity cannot be less then 1" if cart_item_params[:quantity].to_i < 1

				CartItem.find(params[:cart_item_id]).update!(quantity: cart_item_params[:quantity])

				json_response({
					status: 200,
					data: nil,
					message: "item updated",
					errMessage: nil
				})
			rescue ActiveRecord::RecordInvalid => e
					raise ExceptionHandler::RegularError, e
			end
	end


	def delete_cart_item
		begin
			raise ExceptionHandler::RegularError, "cart_id is missing from params" if params[:cart_id].blank?
			raise ExceptionHandler::RegularError, "cart_item_id is missing from params" if params[:cart_item_id].blank?


			cart = Cart.where(id: params[:cart_id], checked_out: false, is_active: true)
			raise ExceptionHandler::RegularError, "could not find cart" unless cart.exists?

			cart_item = CartItem.where(id: params[:cart_item_id], checked_out: false, is_active: true, is_deleted: false)
			raise ExceptionHandler::RegularError, "could not find cart item/item delted" unless cart_item.exists?

			# raise ExceptionHandler::RegularError, "quantity cannot be less then 1" if cart_item_params[:quantity].to_i < 1

			CartItem.find(params[:cart_item_id]).update!(is_deleted: true)

			json_response({
				status: 200,
				data: nil,
				message: "item removed",
				errMessage: nil
			})
		rescue ActiveRecord::RecordInvalid => e
				raise ExceptionHandler::RegularError, e
		end
	end

	private
		def cart_item_params
			params.require(:data).permit(:value, :quantity, :card_code)
			rescue => e
					raise ExceptionHandler::RegularError, e || "you are missing the data field"
		end
end
