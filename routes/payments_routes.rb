# frozen_string_literal: true

# HTTP mapping for payments. No business logic (see AGENTS.md §5).
# POST /webhook is public (Wompi calls it without JWT); all other
# /payments* endpoints require auth.

class App
  before '/api/v1/payments*' do
    pass if request.path_info == '/api/v1/payments/webhook' && request.request_method == 'POST'

    require_auth!
  end

  post '/api/v1/payments/webhook' do
    status_code, body = PaymentsController.webhook(json_attrs)
    render_result(status_code, body)
  end

  post '/api/v1/payments' do
    status_code, body = PaymentsController.create(json_attrs, current_user)
    render_result(status_code, body)
  end

  get '/api/v1/payments/:id' do
    status_code, body = PaymentsController.show(params[:id], current_user)
    render_result(status_code, body)
  end
end
