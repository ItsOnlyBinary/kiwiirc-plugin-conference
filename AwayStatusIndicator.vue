<template>
    <span
        v-if="shouldShowStatus"
        :class="{ 'kiwi-awaystatusindicator': !isConference,
                  'kiwi-awaystatusindicator--away': isAway,
                  'kiwi-awaystatusindicator--conference fa fa-video-camera': isConference,
                  'kiwi-awaystatusindicator--self': isUserSelf }"
        @click="toggleSelfAway()"
    />
</template>

<script>
'kiwi public';

export default {
    props: ['network', 'user', 'toggle'],
    computed: {
        isUserSelf() {
            if (this.toggle === false) {
                return false;
            }
            let user = this.$state.getUser(this.network.id, this.network.nick);
            return this.user === user;
        },
        isAway() {
            return this.user && this.user.isAway() && this.user.away.indexOf(kiwi.inConferenceText) === -1;
        },
        isConference() {
            let buffer = this.$state.getActiveBuffer();
            return this.user && this.user.isAway() && this.user.away.indexOf(kiwi.inConferenceText + ' ' + buffer.name) === 0;
        },
        shouldShowStatus() {
            if (!this.$state.setting('showAwayStatusIndicators')) {
                return false;
            }

            if (this.network.state !== 'connected') {
                return false;
            }

            let awayNotifyEnabled = this.network.ircClient.network.cap.isEnabled('away-notify');
            return this.$state.setting('buffers.who_loop') || awayNotifyEnabled;
        },
    },
    methods: {
        toggleSelfAway() {
            if (this.isUserSelf) {
                let val = this.user.isAway();
                this.network.ircClient.raw('AWAY', val ? '' : 'Currently away');
            }
        },
    },
};
</script>

<style>

.kiwi-awaystatusindicator {
    display: inline-block;
    width: 7px;
    height: 7px;
    border-radius: 50%;
    margin: 0 4px 0 0;
    border: 1px solid #fff;
    transition: background 0.2s;
}

.kiwi-awaystatusindicator--self {
    cursor: pointer;
}

.kiwi-awaystatusindicator--conference {
    display: inline-block;
    font-size: 10px;
    width: 9px;
    height: 9px;
    margin: 0 4px 0 0;
}

</style>
