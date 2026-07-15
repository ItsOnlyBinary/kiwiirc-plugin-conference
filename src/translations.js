/* global kiwi:true */

import * as config from '@/config.js';

const TextFormatting = kiwi.require('helpers/TextFormatting');

export default {
    'en-us': {
        notSupported: 'This browser is not supported.\nPlease update your browser.',
        closeConference: 'Close the current Video Room?',
        joinNow: 'Join now!',
        inviteText: '{{ nick }} is inviting you to a private Video Room.',
        joinText: '{{ nick }} has joined the Video Room.',
        participantsMore: 'more...',
        startConference: 'Start Video Room',
        endConference: 'End Video Room',
        conferenceFailedToken: 'Video Room: failed to obtain authentication token',
        conferenceFailedReauth: 'Video Room: failed to re-authenticate',
        conferenceError: 'Video Room: {{ error }}',
    },
    'it-it': {
        notSupported: 'Questo browser non è supportato.\nAggiorna il tuo browser.',
        closeConference: 'Chiudere la Video Room corrente?',
        joinNow: 'Partecipa ora!',
        inviteText: '{{ nick }} ti sta invitando ad una Video Room privata.',
        joinText: '{{ nick }} si è unito alla Video Room.',
        participantsMore: 'altri...',
        startConference: 'Avvia Video Room',
        endConference: 'Termina Video Room',
        conferenceFailedToken: 'Video Room: impossibile ottenere il token di autenticazione',
        conferenceFailedReauth: 'Video Room: errore durante la ri-autenticazione',
        conferenceError: 'Errore Video Room: {{ error }}',
    },
};

export function t(...args) {
    return TextFormatting.t(config.configBase + ':' + args.shift(), ...args);
}
