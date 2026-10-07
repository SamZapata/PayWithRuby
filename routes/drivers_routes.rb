# frozen_string_literal: true

# HTTP mapping for drivers. No business logic (see AGENTS.md §5).

class App
  before '/api/v1/drivers*' do
    require_auth! unless request.request_method == 'GET'
  end

  get '/api/v1/drivers' do
    status_code, body = DriversController.index(status: params[:status] || params['status'])
    render_result(status_code, body)
  end

  get '/api/v1/drivers/:id' do
    status_code, body = DriversController.show(params[:id])
    render_result(status_code, body)
  end

  post '/api/v1/drivers' do
    status_code, body = DriversController.create(json_attrs)
    render_result(status_code, body)
  end

  put '/api/v1/drivers/:id' do
    status_code, body = DriversController.update(params[:id], json_attrs)
    render_result(status_code, body)
  end

  patch '/api/v1/drivers/:id' do
    status_code, body = DriversController.update(params[:id], json_attrs)
    render_result(status_code, body)
  end

  delete '/api/v1/drivers/:id' do
    status_code, body = DriversController.destroy(params[:id])
    render_result(status_code, body)
  end
end
