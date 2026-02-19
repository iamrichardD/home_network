# Proxmox SSL Automation with Let's Encrypt & Cloudflare DNS-01

Automated SSL certificate issuance and renewal for Proxmox VE using Let's Encrypt and the Cloudflare DNS-01 challenge. This setup is designed for internal networks where port 80/443 cannot or should not be exposed to the public internet.

## TL;DR (Quick Start)

For experienced users who just want to get it running:

1.  **Clone this repository** to your Proxmox host (or copy the files).
2.  **Create configuration:**
    ```bash
    cp .env.example .env
    chmod 600 .env
    nano .env
    ```
    *Fill in `CF_EMAIL`, `CF_TOKEN`, and `DOMAIN`.*
3.  **Run the script:**
    ```bash
    chmod +x setup-ssl.sh
    ./setup-ssl.sh
    ```
4.  **Verify:** Check Proxmox GUI > System > Certificates.

---

## Deep Dive: Hows and Whys

### Why DNS-01 Challenge?

The standard HTTP-01 challenge requires you to expose port 80 on your server to the public internet so Let's Encrypt can verify ownership by fetching a file.

**Security Risk:** Opening ports on your firewall increases your attack surface.
**Solution (DNS-01):** Instead of checking a file, Let's Encrypt asks you to create a specific TXT record in your domain's DNS. Since you control the DNS (via Cloudflare API), you can prove ownership **without opening any incoming ports**.

### Split-Horizon DNS (Pi-hole / Unbound)

In this setup, `proxmox.example.com` resolves differently depending on where you are:

*   **Public Internet (Cloudflare):** Resolves to a private IP (e.g., `192.168.1.10`) or is proxied via Cloudflare Tunnels. Even if it resolves to a private IP, it's useless to an external attacker without VPN access.
*   **Internal Network (Pi-hole/Unbound):** Your local DNS servers resolve `proxmox.example.com` directly to the LAN IP `192.168.1.10`.

This allows you to use a valid, publicly trusted SSL certificate for a service that is only accessible internally.

### Cloudflare Tunnels Integration

If you want to access Proxmox remotely without a VPN or port forwarding, you can use **Cloudflare Tunnels**.
1.  Run `cloudflared` on a machine in your network.
2.  Configure a tunnel to point `proxmox.example.com` to `https://192.168.1.10:8006`.
3.  **Important:** You must set "No TLS Verify" in the Cloudflare Tunnel settings for this origin, OR ensure the tunnel trusts the Let's Encrypt CA (which it does by default).

## Security Best Practices

### Cloudflare API Token Scoping (Least Privilege)

**NEVER** use your Global API Key. If compromised, it gives full access to your entire Cloudflare account.

Instead, create a scoped **API Token**:

1.  Go to [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens).
2.  Create Custom Token.
3.  **Permissions:**
    *   `Zone` -> `DNS` -> `Edit`
4.  **Zone Resources:**
    *   `Include` -> `Specific Zone` -> `example.com`
5.  **Client IP Address Filtering (Optional but Recommended):**
    *   Restrict usage to your home IP address if it is static.

### File Permissions

The `.env` file contains your API token. It must be protected.
*   Run `chmod 600 .env` to ensure only the owner (root) can read it.
*   The `.gitignore` file is pre-configured to prevent accidentally committing `.env` to a Git repository.
