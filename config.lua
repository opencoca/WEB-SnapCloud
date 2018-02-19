local config = require('lapis.config')

-- TODO: Pull out the different pieces into a dev only section
config({'development', 'production'}, {
    postgres = {
        host = os.getenv('DATABASE_URL') or '127.0.0.1:5432',
        user = os.getenv('DATABASE_USERNAME') or 'snap',
        password = os.getenv('DATABASE_PASSWORD') or 'snap-cloud-password',
        database = os.getenv('DATABASE_NAME') or 'snap_cloud'
    },
    enable_https = true,
    session_name = 'snapsession',
    secret = os.getenv('SESSION_SECRET_BASE') or 'this is a secret',

    -- Change to the relative (or absolute) path of your disk storage
    -- directory.  Note that the user running Lapis needs to have
    -- read & write permissions to that path.
    store_path = 'store',

    -- for sending email
    mail_user = os.getenv('MAIL_SMTP_USER'),
    mail_password = os.getenv('MAIL_SMTP_PASSWORD'),
    mail_server = os.getenv('MAIL_SMTP_SERVER'),
    mail_from_name = "Snap!Cloud",
    mail_from = "postmaster@snap-cloud.cs10.org",
    mail_footer = "<br/><br/><p><small>Please do not reply to this email. This message was automatically generated by the Snap!Cloud. To contact an actual human being, please write to <a href='mailto:snap-support@bjc.berkeley.edu'>snap-support@bjc.berkeley.edu</a></small></p>"
})

config('development', {
    use_daemon = 'off',
    site_name = 'dev | Snap Cloud',
    hostname = 'localhost',
    port = os.getenv('PORT') or 8080,
    ssl_cert_name = os.getenv('SSL_CERT_NAME') or 'host',
    enable_auto_ssl = 'false',
    num_workers = 1,
    code_cache = 'off',
    log_location = 'stderr',
    dns_resolver = '',
    secret = os.getenv('SESSION_SECRET_BASE') or 'this is a secret',
    measure_performance = true
})

config('production', {
    use_daemon = 'on',
    port = os.getenv('PORT') or 80,
    site_name = 'Snap Cloud',
    hostname = 'snap-cloud.cs10.org',
    ssl_cert_name = os.getenv('SSL_CERT_NAME') or 'snap-cloud.cs10.org',
    enable_auto_ssl = 'true', -- lapis needs a string
    secret = os.getenv('SESSION_SECRET_BASE'),
    num_workers = 12,
    code_cache = 'on',

    log_location = 'logs/error.log',
    -- DigitalOcean DNS resolvers
    dns_resolver = '67.207.67.2 ipv6=off',

    --- TODO: See if we can turn this on without a big hit
    measure_performance = false
})
