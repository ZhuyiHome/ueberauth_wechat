# Überauth Wechat

> Wechat OAuth2 strategy for Überauth.

## Installation

1. Setup your application at [Wechat Developer](https://open.weixin.qq.com).

1. Add `:ueberauth_wechat` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_wechat, "~> 0.1"}]
    end
    ```

1. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_wechat]]
    end
    ```

1. Add Wechat to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        wechat: {Ueberauth.Strategy.Wechat, []}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Wechat.OAuth,
      client_id: System.get_env("WECHAT_CLIENT_ID"),
      client_secret: System.get_env("WECHAT_CLIENT_SECRET")
    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller

      pipeline :browser do
        plug Ueberauth
        ...
       end
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. You controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initial the request through:

    /auth/wechat

Or with options:

    /auth/wechat?scope=snsapi_userinfo

By default the requested scope is "snsapi_userinfo". Scope can be configured either explicitly as a `scope` query value on the request path or in your configuration:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    wechat: {Ueberauth.Strategy.Wechat, [default_scope: "snsapi_userinfo"]}
  ]
```

## License

Please see [LICENSE](https://github.com/ZhuyiHome/ueberauth_wechat/blob/master/LICENSE) for licensing details.
