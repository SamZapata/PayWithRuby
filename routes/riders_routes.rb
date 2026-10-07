# frozen_string_literal: true

# HTTP mapping for riders. No business logic (see AGENTS.md §5).
# P1 note: Services skipped for pure CRUD (no business rules to orchestrate).

class App
  before '/api/v1/riders*' do
    require_auth! unless request.request_method == 'GET'
  end

  helpers do
    def json_attrs
      if request.media_type == 'application/json'
        raw = request.body.read
        return {} if raw.nil? || raw.strip.empty?

        JSON.parse(raw)
      else
        params.reject { |k, _| %w[splat captures].include?(k) }
      end
    rescue JSON::ParserError
      halt 400, { error: { code: 'bad_request', message: 'Invalid JSON body' } }.to_json
    end

    def render_result(status_code, body)
      status status_code
      return '' if body.nil? && status_code == 204

      (body || {}).to_json
    end
  end

  get '/api/v1/riders' do
    status_code, body = RidersController.index(status: params[:status] || params['status'])
    render_result(status_code, body)
  end

  get '/api/v1/riders/:id' do
    status_code, body = RidersController.show(params[:id])
    render_result(status_code, body)
  end

  post '/api/v1/riders' do
    status_code, body = RidersController.create(json_attrs)
    render_result(status_code, body)
  end

  put '/api/v1/riders/:id' do
    status_code, body = RidersController.update(params[:id], json_attrs)
    render_result(status_code, body)
  end

  patch '/api/v1/riders/:id' do
    status_code, body = RidersController.update(params[:id], json_attrs)
    render_result(status_code, body)
  end

  delete '/api/v1/riders/:id' do
    status_code, body = RidersController.destroy(params[:id])
    render_result(status_code, body)
  end
end
