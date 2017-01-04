defmodule Ueberauth.Strategy.Wechat do
  @moduledoc """
  Provides an Ueberauth strategy for authenticating with Wechat.

  ### Setup

  Create an application in Wechat for you to use.

  Register a new application at: [your wechat developer page](https://open.weixin.qq.com) and get the `client_id` and `client_secret`.

  Include the provider in your configuration for Ueberauth

      config :ueberauth, Ueberauth,
        providers: [
          wechat: { Ueberauth.Strategy.Wechat, [] }
        ]

  Then include the configuration for Wechat.

      config :ueberauth, Ueberauth.Strategy.Wechat.OAuth,
        client_id: System.get_env("WECHAT_CLIENT_ID"),
        client_secret: System.get_env("WECHAT_CLIENT_SECRET")

  If you haven't already, create a pipeline and setup routes for your callback handler

      pipeline :auth do
        Ueberauth.plug "/auth"
      end

      scope "/auth" do
        pipe_through [:browser, :auth]

        get "/:provider/callback", AuthController, :callback
      end


  Create an endpoint for the callback where you will handle the `Ueberauth.Auth` struct

      defmodule MyApp.AuthController do
        use MyApp.Web, :controller

        def callback_phase(%{ assigns: %{ ueberauth_failure: fails } } = conn, _params) do
          # do things with the failure
        end

        def callback_phase(%{ assigns: %{ ueberauth_auth: auth } } = conn, params) do
          # do things with the auth
        end
      end

  You can edit the behaviour of the Strategy by including some options when you register your provider.

  To set the `uid_field`

      config :ueberauth, Ueberauth,
        providers: [
          wechat: { Ueberauth.Strategy.Wechat, [uid_field: :nickname] }
        ]

  Default is `:openid`

  To set the default 'scopes' (permissions):

      config :ueberauth, Ueberauth,
        providers: [
          wechat: { Ueberauth.Strategy.Wechat, [default_scope: "snsapi_userinfo"] }
        ]

  Deafult is "snsapi_userinfo"
  """
  use Ueberauth.Strategy, uid_field: :openid,
                          default_scope: "snsapi_userinfo",
                          oauth2_module: Ueberauth.Strategy.Wechat.OAuth

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles the initial redirect to the Wechat authentication page.

  To customize the scope (permissions) that are requested by Wechat include them as part of your url:

      "/auth/wechat?scope=snsapi_userinfo"

  You can also include a `state` param that Wechat will return to you.
  """
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)
    opts = [redirect_uri: callback_url(conn), scope: scopes]

    opts =
      if conn.params["state"], do: Keyword.put(opts, :state, conn.params["state"]), else: opts

    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  @doc """
  Handles the callback from Wechat. When there is a failure from Wechat the failure is included in the
  `ueberauth_failure` struct. Otherwise the information returned from Wechat is returned in the `Ueberauth.Auth` struct.
  """
  def handle_callback!(%Plug.Conn{ params: %{ "code" => code } } = conn) do
    module = option(conn, :oauth2_module)
    token = apply(module, :get_token!, [[code: code]])

    if token.access_token == nil do
      set_errors!(conn, [error(token.other_params["errcode"], token.other_params["errmsg"])])
    else
      fetch_user(conn, token)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc """
  Cleans up the private area of the connection used for passing the raw Wechat response around during the callback.
  """
  def handle_cleanup!(conn) do
    conn
    |> put_private(:wechat_user, nil)
    |> put_private(:wechat_token, nil)
  end

  @doc """
  Fetches the uid field from the Wechat response. This defaults to the option `uid_field` which in-turn defaults to `openid`
  """
  def uid(conn) do
    conn.private.wechat_user[option(conn, :uid_field) |> to_string]
  end

  @doc """
  Includes the credentials from the Wechat response.
  """
  def credentials(conn) do
    token = conn.private.wechat_token
    scopes = (token.other_params["scope"] || "")
    |> String.split(",")

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type,
      expires: !!token.expires_at,
      scopes: scopes
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    user = conn.private.wechat_user

    %Info{
      name: user["nickname"],
      image: user["headimgurl"],
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the Wechat callback.
  """
  def extra(conn) do
    %Extra {
      raw_info: %{
        token: conn.private.wechat_token,
        user: conn.private.wechat_user
      }
    }
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :wechat_token, token)
    fetch_user_url = "/userinfo?access_token=#{token.access_token}&openid=#{token.openid}"
    case Ueberauth.Strategy.Wechat.OAuth.get(token, fetch_user_url) do
      { :ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])
      { :ok, %OAuth2.Response{status_code: status_code, body: user} } when status_code in 200..399 ->
        put_private(conn, :wechat_user, user)
      { :error, %OAuth2.Error{reason: reason} } ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end
end
