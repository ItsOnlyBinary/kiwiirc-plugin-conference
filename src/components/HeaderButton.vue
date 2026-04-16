<template>
    <div v-if="showButton" class="p-conference-button" :class="{ 'kiwi-header-option--active': pluginState.isActive }">
        <div v-if="closePrompt" class="p-conference-prompt">
            <div>Close the current conference?</div>
            <input-confirm :flip-connotation="true" @ok="closeConference()" @submit="hideToast()" />
        </div>
        <button
            type="button"
            :aria-label="pluginState.isActive ? 'Close conference' : 'Open conference'"
            @click="openConference()"
        >
            <i aria-hidden="true" :class="buttonIcon" class="fa" />
        </button>
    </div>
</template>

<script setup>
/* global kiwi:true */
import { ref, computed } from 'vue';
import JitsiMediaView from './JitsiMediaView.vue';
import * as config from '../config.js';

const props = defineProps({
    network: { type: Object, required: true },
    buffer: { type: Object, required: true },
    sidebarState: { type: Object, required: true },
    pluginState: { type: Object, required: true },
});

const closePrompt = ref(false);

const showButton = computed(() => config.isAllowedBuffer(props.buffer));
const buttonIcon = computed(() => config.setting('buttonIcon'));

function openConference() {
    if (!props.pluginState.isActive) {
        props.pluginState.isActive = true;
        kiwi.emit('mediaviewer.show', {
            component: JitsiMediaView,
            componentProps: {
                pluginState: props.pluginState,
                buffer: props.buffer,
            },
        });
        return;
    }

    closePrompt.value = true;
}

function closeConference() {
    kiwi.emit('mediaviewer.hide');
}

function hideToast() {
    closePrompt.value = false;
}
</script>

<style lang="scss">
.p-conference-prompt {
    position: absolute;
    top: 44px;
    right: 10px;
    padding: 10px;
    font-size: 1.2em;
    font-weight: 400;
    color: var(--brand-default-fg, #000);
    background-color: var(--brand-default-bg, #fff);
    border-radius: 0 0 10px 10px;

    a.u-button-warning {
        color: var(--brand-default-bg);
        background-color: var(--brand-error);
    }
}
</style>
