# KiwiIRC - Jitsi-meet JWT authentication

### Installing jitsi-meet

It is recommended to use the docker method to install jitsi-meet as this allows better control over the version of jitsi-meet that is used.

The documentation for docker install can be found [here](https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker/)

### Configuring docker-jitsi-meet

The files from `jitsi-meet_xxx` should be copied to `prosody/prosody-plugins-custom` within your `CONFIG` path.

There are several environment variables that need setting for docker-jitsi-meet to allow it to work well with kiwiirc-plugin-conference, these are listed below:

```
AUTH_TYPE=jwt
ENABLE_AUTH=1
ENABLE_AUTO_OWNER=0
ENABLE_BREAKOUT_ROOMS=0
ENABLE_GUESTS=0
ENABLE_LOBBY=0
ENABLE_PREJOIN_PAGE=0
ENABLE_WELCOME_PAGE=0
JICOFO_ENABLE_AUTH=0
JWT_ACCEPTED_ISSUERS=<YOUR IRC URL eg irc.example.com>
JWT_APP_ID=<YOUR IRC URL eg irc.example.com>
JWT_APP_SECRET=<YOUR SECRET FOR EXTJWT>
JWT_AUTH_TYPE=kiwiirc_token
JWT_ENABLE_DOMAIN_VERIFICATION=1
JWT_TOKEN_AUTH_MODULE=kiwiirc_token_verification
XMPP_MUC_MODULES=kiwiirc_token_affiliation
```

It is also advised to set `JITSI_IMAGE_VERSION` so that it does not update unexpectedly.

### Special kiwiirc environment variables

Some environment variables have been added to allow tweaking how the irc token is treated, these are listed below.

```
KIWIIRC_EVERYONE_MODERATOR=0        # makes every user with a token becomes jitsi moderator.
KIWIIRC_DISABLE_OWNER_MODERATOR=0   # stops channel owner from becoming a moderator.
KIWIIRC_DISABLE_OP_MODERATOR=0      # stops op's from becoming a moderator (network operators are always moderators).
KIWIIRC_DISABLE_HALFOP_MODERATOR=0  # stops half-op's from becoming a moderator.
KIWIIRC_ENABLE_NO_MODE_MEMBER=0     # users without voice will be given "member" affiliation.
```


### Allowing users without tokens to connect

To allow users with the link to the conference to connect without a token set the following environment variables
```
ENABLE_GUESTS=1
ENABLE_PREJOIN_PAGE=1
```
