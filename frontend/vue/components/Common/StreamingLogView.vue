<template>
    <b-overlay
        variant="card"
        :show="loading"
    >
        <b-form-group label-for="modal_scroll_to_bottom">
            <b-form-checkbox
                id="modal_scroll_to_bottom"
                v-model="scrollToBottom"
            >
                {{ $gettext('Automatically Scroll to Bottom') }}
            </b-form-checkbox>
        </b-form-group>

        <textarea
            id="log-view-contents"
            ref="textarea"
            class="form-control log-viewer"
            spellcheck="false"
            readonly
            :value="logs"
        />
    </b-overlay>
</template>

<script>

/* TODO Options API */

export default {
    name: 'StreamingLogView',
    props: {
        logUrl: {
            type: String,
            required: true,
        }
    },
    data() {
        return {
            loading: false,
            logs: '',
            currentLogPosition: null,
            timeoutUpdateLog: null,
            scrollToBottom: true,
        };
    },
    mounted() {
        this.loading = true;

        this.axios({
            method: 'GET',
            url: this.logUrl
        }).then((resp) => {
            if (resp.data.contents !== '') {
                this.logs = resp.data.contents + "\n";
                this.scrollTextarea();
            } else {
                this.logs = '';
            }

            this.currentLogPosition = resp.data.position;

            if (!resp.data.eof) {
                this.timeoutUpdateLog = setTimeout(this.updateLogs, 2500);
            }
        }).finally(() => {
            this.loading = false;
        });
    },
    beforeUnmount() {
        clearTimeout(this.timeoutUpdateLog);
    },
    methods: {
        updateLogs() {
            this.axios({
                method: 'GET',
                url: this.logUrl,
                params: {
                    position: this.currentLogPosition
                }
            }).then((resp) => {
                if (resp.data.contents !== '') {
                    this.logs = this.logs + resp.data.contents + "\n";
                    this.scrollTextarea();
                }
                this.currentLogPosition = resp.data.position;

                if (!resp.data.eof) {
                    this.timeoutUpdateLog = setTimeout(this.updateLogs, 2500);
                }
            });
        },
        getContents() {
            return this.logs;
        },
        scrollTextarea() {
            if (this.scrollToBottom) {
                this.$nextTick(() => {
                    const textarea = this.$refs.textarea;
                    textarea.scrollTop = textarea.scrollHeight;
                });
            }
        }
    }
};
</script>
