# Jomashop UDL Server

A simplified, production-ready fork of [fdocr/udl-server](https://github.com/fdocr/udl-server) — stripped down to a single-purpose path-passthrough redirect server for Jomashop mobile app deep linking.

## How it works

Bounces traffic through a separate domain so iOS Universal Links and Android App Links trigger correctly — even when users are browsing inside webviews (Instagram, TikTok, etc).

```mermaid
flowchart TD
    A["📱 User taps link in Instagram/TikTok\nudl.jomashop.com/rolex.html"] --> B{"OS checks AASA / assetlinks\non udl.jomashop.com"}
    B -- "App installed" --> C["🟢 Jomashop App opens directly\nDeep links to /rolex.html"]
    B -- "App not installed" --> D["⚡ UDL Server\nudl.jomashop.com"]
    D -- "302 Redirect" --> E["🌐 www.jomashop.com/rolex.html"]

    style A fill:#dbeafe,stroke:#2563eb
    style B fill:#fef3c7,stroke:#d97706
    style C fill:#d1fae5,stroke:#059669
    style D fill:#fef3c7,stroke:#d97706
    style E fill:#e5e7eb,stroke:#6b7280
```

## Usage

All paths are forwarded to `DEFAULT_DESTINATION`:

- `https://udl.jomashop.com/` → redirects to `DEFAULT_DESTINATION`
- `https://udl.jomashop.com/watches/rolex` → redirects to `DEFAULT_DESTINATION/watches/rolex`

## Environment Variables

| Variable | Description | Example |
|---|---|---|
| `DEFAULT_DESTINATION` | Target site for all redirects | `https://www.jomashop.com` |
| `PORT` | Server port (default `3000`) | `3000` |

## Performance

Crystal + Kemal — microsecond response times.

![performance](nanosecond-response-times.png)
