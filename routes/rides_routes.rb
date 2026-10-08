# frozen_string_literal: true

# HTTP mapping for rides. No business logic (see AGENTS.md §5).

class App
  before '/api/v1/rides*' do
    require_auth! unless request.request_method == 'GET'
  end

  get '/api/v1/rides' do
    status_code, body = RidesController.index(
      status: params[:status] || params['status'],
      rider_id: params[:rider_id] || params['rider_id'],
      driver_id: params[:driver_id] || params['driver_id']
    )
    render_result(status_code, body)
  end

  get '/api/v1/rides/:id' do
    status_code, body = RidesController.show(params[:id])
    render_result(status_code, body)
  end

  post '/api/v1/rides' do
    status_code, body = RidesController.create(json_attrs, current_user)
    render_result(status_code, body)
  end

  patch '/api/v1/rides/:id/accept' do
    status_code, body = RidesController.accept(params[:id], json_attrs, current_user)
    render_result(status_code, body)
  end

  patch '/api/v1/rides/:id/complete' do
    status_code, body = RidesController.complete(params[:id], current_user)
    render_result(status_code, body)
  end

  patch '/api/v1/rides/:id/cancel' do
    status_code, body = RidesController.cancel(params[:id], current_user)
    render_result(status_code, body)
  end
end
