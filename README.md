# JomaShop UDL Server

Private Universal Deep Link server for JomaShop mobile app deep linking.

## How it works

Bounces traffic through a separate domain so iOS Universal Links and Android App Links trigger correctly — even when users are browsing inside webviews (Instagram, TikTok, etc).

![diagram](udl-server-deep-link.png)

## Usage

Redirect through the UDL server with the `r` query parameter:

```
https://your-udl-domain.com/?r=https://www.jomashop.com/product-page
```

### Default destination

If `DEFAULT_DESTINATION` is set and no `r` param is provided:

- `https://your-udl-domain.com/` → redirects to `DEFAULT_DESTINATION`
- `https://your-udl-domain.com/watches/rolex` → redirects to `DEFAULT_DESTINATION + /watches/rolex`

### Whitelist destinations

`WHITELIST_DESTINATIONS` restricts redirect targets to approved hosts (comma-separated):

```
WHITELIST_DESTINATIONS=www.jomashop.com,jomashop.com
```

`DEFAULT_DESTINATION` host is always implicitly allowed.

## Environment Variables

| Variable | Description | Example |
|---|---|---|
| `DEFAULT_DESTINATION` | Fallback redirect when no `r` param | `https://www.jomashop.com` |
| `WHITELIST_DESTINATIONS` | Comma-separated allowed redirect hosts | `www.jomashop.com,jomashop.com` |
| `PORT` | Server port (default `3000`) | `3000` |

## Performance

Crystal + Kemal — microsecond response times.

![performance](nanosecond-response-times.png)
