<template>
    <div class="plugin-conference-join">
        <div class="plugin-conference-jointext">
            {{ buffer.isQuery() ? inviteText : joinText }}
        </div>
        <button v-if="!pluginState.isActive" type="button" class="u-button u-button-primary" @click="openJitsi()">
            <i aria-hidden="true" class="fa fa-phone" />
            <span class="plugin-conference-joinbutton">{{ joinButtonText }}</span>
        </button>
    </div>
</template>

<script setup>
/* global kiwi:true */
import { computed } from 'vue';
import JitsiMediaView from './JitsiMediaView.vue';
import * as config from '../config.js';

const props = defineProps({
    buffer: { type: Object, required: true },
    message: { type: Object, required: true },
    idx: { type: Number, required: true },
    ml: { type: Object, required: true },
    pluginState: { type: Object, required: true },
    inviteState: { type: Object, required: true },
});

const nicks = computed(() => {
    const maxLength = config.setting('maxParticipantsLength');
    const showNicks = [];
    let length = 0;
    for (let i = 0; i < props.inviteState.members.length; i++) {
        const nick = props.inviteState.members[i];
        length += nick.length;
        if (length > maxLength) {
            showNicks.push(config.setting('participantsMore'));
            break;
        }
        showNicks.push(nick);
    }
    return showNicks;
});

const joinButtonText = computed(() => config.setting('joinButtonText'));
const inviteText = computed(() => config.setting('inviteText').replace('{{ nick }}', nicks.value.join(', ')));
const joinText = computed(() => config.setting('joinText').replace('{{ nick }}', nicks.value.join(', ')));

function openJitsi() {
    props.pluginState.isActive = true;
    kiwi.emit('mediaviewer.show', {
        component: JitsiMediaView,
        componentProps: {
            pluginState: props.pluginState,
            buffer: props.buffer,
        },
    });
}
</script>

<style>
.plugin-conference-join {
    box-sizing: border-box;
    width: 100%;
    padding: 20px;
    font-size: 1.05em;
    line-height: 1.05em;
    text-align: center;
    background: var(--brand-midtone);
}

.plugin-conference-jointext {
    display: inline-block;
    margin-right: 10px;
    line-height: 2em;
}

.plugin-conference-joinbutton {
    margin-left: 8px;
}
</style>
