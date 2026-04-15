<template>
    <div class="p-conference-jitsi">
        <div v-if="isJoined" class="p-conference-overlay">{{ roomName }} @ {{ network.name }}</div>
        <div v-if="isLoading" class="p-conference-loading">
            <svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
                <g>
                    <circle cx="12" cy="2.5" r="1.5" opacity="0.14" />
                    <circle cx="16.75" cy="3.77" r="1.5" opacity="0.29" />
                    <circle cx="20.23" cy="7.25" r="1.5" opacity="0.43" />
                    <circle cx="21.5" cy="12" r="1.5" opacity="0.57" />
                    <circle cx="20.23" cy="16.75" r="1.5" opacity="0.71" />
                    <circle cx="16.75" cy="20.23" r="1.5" opacity="0.86" />
                    <circle cx="12" cy="21.5" r="1.5" />
                    <animateTransform
                        attributeName="transform"
                        calcMode="discrete"
                        dur="0.75s"
                        repeatCount="indefinite"
                        type="rotate"
                        values="0 12 12;30 12 12;60 12 12;90 12 12;120 12 12;150 12 12;180
                            12 12;210 12 12;240 12 12;270 12 12;300 12 12;330 12 12;360 12 12"
                    />
                </g>
            </svg>
        </div>
        <div v-else-if="notSupported" class="p-conference-notsupported">
            This browser is not supported.<br />Please update your browser.
        </div>
    </div>
</template>

<script>
/* global kiwi:true */
import platform from 'platform';
import * as config from '../config.js';
import * as utils from '../lib/utils.js';

const MAX_RECONNECT_ATTEMPTS = 3;

export default {
    props: ['componentProps'],
    data() {
        return {
            api: null,
            link: '',
            token: '',
            encodedRoomName: '',
            isJoined: false,
            isLoading: false,
            loadingAnimation: null,
            notSupported: false,
        };
    },
    computed: {
        roomName() {
            if (this.buffer.isQuery()) {
                let members = [this.network.nick, this.buffer.name];
                members.sort();
                return members.join('+');
            }
            return this.buffer.name;
        },
        buffer() {
            return this.componentProps.buffer;
        },
        network() {
            return this.buffer.getNetwork();
        },
    },
    async mounted() {
        if (platform.name === 'IE') {
            this.notSupported = true;
            return;
        }

        this.isLoading = true;

        if (config.setting('secure')) {
            try {
                this.token = await this.fetchToken();
            } catch (e) {
                this.addLocalMessage('Conference: failed to obtain authentication token');
                this.isLoading = false;
                return;
            }
        }

        this.scriptLoad();

        // MediaViewer also sets a height on mounted()
        // and is called after this mounted()
        this.$nextTick(() => {
            this.$parent.setHeight(config.setting('viewHeight'));
        });
    },
    beforeDestroy() {
        this.componentProps.pluginState.isActive = false;
        clearTimeout(this.reconnectTimeout);
        // prevent any pending reconnect from proceeding after destroy
        this.reconnectAttempts = MAX_RECONNECT_ATTEMPTS;

        let mediaviewer = this.$el.parentElement;
        if (mediaviewer) {
            mediaviewer.style.height = '';
        }

        if (this.api) {
            this.api.dispose();
        }
    },
    methods: {
        fetchToken() {
            return new Promise((resolve, reject) => {
                const timeout = setTimeout(() => {
                    kiwi.off('irc.raw.EXTJWT', handler);
                    reject(new Error('EXTJWT timeout'));
                }, 10000);

                let token = '';
                const handler = (command, message) => {
                    if (message.params[2] === '*') {
                        token = message.params[3];
                    } else {
                        token += message.params[2];
                        clearTimeout(timeout);
                        kiwi.off('irc.raw.EXTJWT', handler);
                        setTimeout(() => resolve(token), 60000);
                        // resolve(token);
                    }
                };

                kiwi.on('irc.raw.EXTJWT', handler);
                this.network.ircClient.raw('EXTJWT', this.buffer.isQuery() ? '*' : this.roomName);
            });
        },
        addLocalMessage(text) {
            kiwi.state.addMessage(this.buffer, {
                time: Date.now(),
                nick: '',
                message: text,
                type: 'error',
            });
        },
        scriptLoad() {
            const roomNamePromise = utils.encodeRoomName(this.network.connection.server + '/' + this.roomName);
            let scr = document.createElement('script');
            scr.src = 'https://' + config.setting('server') + '/external_api.js';
            scr.onload = async () => {
                const roomName = await roomNamePromise;
                this.encodedRoomName = (this.buffer.isQuery()) ? 'q-' + roomName : roomName;
                this.scriptLoaded();
            };
            scr.defer = true;
            this.$el.appendChild(scr);
        },
        scriptLoaded() {
            let configOverwrite = config.setting('configOverwrite');

            // Disable prejoin page as we are setting the users nick
            configOverwrite.prejoinPageEnabled = false;
            configOverwrite.prejoinConfig = {
                enabled: false,
            };

            if (config.setting('showLink') && !this.link) {
                this.getLink();
            }

            let domain = config.setting('server');
            let options = {
                roomName: this.encodedRoomName,
                userInfo: {
                    displayName: this.network.nick,
                },
                parentNode: this.$el,
                configOverwrite: configOverwrite,
                interfaceConfigOverwrite: config.setting('interfaceConfigOverwrite'),
                onload: () => {
                    this.api.executeCommand('toggleTileView');

                    this.api.addEventListener('videoConferenceJoined', () => {
                        const isReconnect = this.reconnectAttempts > 0;
                        this.isJoined = true;
                        this.isLoading = false;
                        this.reconnectAttempts = 0;

                        if (!isReconnect && (!config.setting('showLink') || this.link)) {
                            this.sendJoinMessage();
                        }
                    });

                    this.api.addEventListener('videoConferenceLeft', () => {
                        console.log('Left Conference');
                        // kiwi.emit('mediaviewer.hide');
                    });

                    this.api.once('browserSupport', (event) => {
                        if (!event.supported) {
                            this.isLoading = false;
                            this.isJoined = false;
                            this.notSupported = true;
                        }
                    });

                    this.api.addEventListener('errorOccurred', async (event) => {
                        if (!event?.error?.message) {
                            return;
                        }
                        if (event?.error?.message === 'Token expired') {
                            this.api.dispose();
                            this.api = null;
                            this.token = await this.fetchToken();
                            this.scriptLoaded();
                        } else {
                            this.addLocalMessage('plugin-conference error: ' + event.error.message);
                        }
                    });
                },
            };

            if (config.setting('secure')) {
                options.jwt = this.token;
            }

            this.api = new window.JitsiMeetExternalAPI(domain, options);
        },
        sendJoinMessage() {
            let msgText = this.buffer.isQuery() ? config.setting('inviteText') : config.setting('joinText');

            msgText = '* ' + msgText.replace('{{ nick }}', this.network.nick);

            if (config.setting('showLink') && this.link) {
                msgText += ' ' + this.link;
            }

            let message = new this.network.ircClient.Message('PRIVMSG', this.buffer.name, msgText);
            message.prefix = this.network.nick;
            message.tags['+kiwiirc.com/conference'] = config.getSetting('tagID');
            this.network.ircClient.raw(message);
        },
        getLink() {
            let link = 'https://' + config.setting('server') + '/' + this.encodedRoomName;
            if (!config.setting('useLinkShortener')) {
                this.link = link;
                return;
            }

            let shortURL = config.setting('linkShortenerURL');
            if (shortURL.indexOf('api-ssl.bitly.com') > -1) {
                this.getBitlyLink(shortURL, link);
            } else {
                this.getShortLink(shortURL, link);
            }
        },
        getShortLink(shortURL, link) {
            let requestURL = shortURL.replace('{{ link }}', link);
            fetch(requestURL)
                .then((r) => r.text())
                .then((result) => {
                    let urlRegex = kiwi.require('helpers/TextFormatting').urlRegex;
                    let isUrl = new RegExp('^' + urlRegex.source + '$');
                    // catch any issues by making sure the result is a url
                    if (isUrl.test(result)) {
                        this.link = result;
                    }
                    if (this.isJoined) {
                        this.sendJoinMessage();
                    }
                });
        },
        getBitlyLink(bitlyURL, link) {
            let apiKey = config.setting('linkShortenerAPIToken');
            let requestURL = bitlyURL + '?access_token=' + apiKey + '&longUrl=' + link;
            fetch(requestURL)
                .then((r) => r.json())
                .then((result) => {
                    this.link = result.url;
                    if (this.isJoined) {
                        this.sendJoinMessage();
                    }
                });
        },
    },
};
</script>

<style lang="scss">
.p-conference-jitsi {
    height: 100%;

    /* fixes firefox showing scrollbar */
    overflow: hidden;
}

.p-conference-overlay {
    position: absolute;
    top: 0;
    left: 0;
    z-index: 10;
    padding: 6px 6px 2px 6px;
    color: #fff;
    background-color: rgba(0, 0, 0, 0.2);
}

.p-conference-loading {
    position: absolute;
    inset: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 20px;
    background-color: rgba(0, 0, 0, 0.6);

    > svg {
        width: min(max(20vb, 80px), 200px);
        height: min(max(20vb, 80px), 200px);
        fill: #fff;
    }

    > i {
        font-size: 100px;
    }
}

.p-conference-notsupported {
    display: inline-block;
    padding: 25px;
    margin: 25px auto;
    font-size: 130%;
    font-weight: 600;
    color: var(--brand-default-fg);
    background-color: var(--brand-error);
    border-radius: 5px;
}
</style>
