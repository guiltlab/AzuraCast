<template>
    <b-modal
        id="move_file"
        ref="modal"
        size="xl"
        centered
        :title="langHeader"
    >
        <b-row class="mb-3 align-items-center">
            <b-col md="6">
                <b-button
                    size="sm"
                    variant="primary"
                    :disabled="dirHistory.length === 0"
                    @click="pageBack"
                >
                    <icon icon="chevron_left" />
                    {{ $gettext('Back') }}
                </b-button>
            </b-col>
            <b-col
                md="6"
                class="text-right"
            >
                <h6 class="m-0">
                    {{ destinationDirectory }}
                </h6>
            </b-col>
        </b-row>
        <b-row>
            <b-col md="12">
                <data-table
                    id="station_media"
                    ref="datatable"
                    :show-toolbar="false"
                    :selectable="false"
                    :fields="fields"
                    :api-url="listDirectoriesUrl"
                    :request-config="requestConfig"
                >
                    <template #cell(directory)="row">
                        <div class="is_dir">
                            <span class="file-icon">
                                <icon icon="folder" />
                            </span>

                            <a
                                href="#"
                                @click.prevent="enterDirectory(row.item.path)"
                            >
                                {{ row.item.name }}
                            </a>
                        </div>
                    </template>
                </data-table>
            </b-col>
        </b-row>
        <template #modal-footer>
            <b-button
                variant="default"
                @click="close"
            >
                {{ $gettext('Close') }}
            </b-button>
            <b-button
                variant="primary"
                @click="doMove"
            >
                {{ $gettext('Move to Directory') }}
            </b-button>
        </template>
    </b-modal>
</template>
<script>
import DataTable from '~/components/Common/DataTable.vue';
import {forEach} from 'lodash';
import Icon from '~/components/Common/Icon';

/* TODO Options API */

export default {
    name: 'MoveFilesModal',
    components: {Icon, DataTable},
    props: {
        selectedItems: {
            type: Object,
            required: true
        },
        currentDirectory: {
            type: String,
            required: true
        },
        batchUrl: {
            type: String,
            required: true
        },
        listDirectoriesUrl: {
            type: String,
            required: true
        }
    },
    emits: ['relist'],
    data() {
        return {
            destinationDirectory: '',
            dirHistory: [],
            fields: [
                {key: 'directory', label: this.$gettext('Directory'), sortable: false}
            ]
        };
    },
    computed: {
        langHeader () {
            return this.$gettext(
                'Move %{ num } File(s) to',
                {num: this.selectedItems.all.length}
            );
        }
    },
    methods: {
        close () {
            this.dirHistory = [];
            this.destinationDirectory = '';

            this.$refs.modal.hide();
        },
        doMove () {
            (this.selectedItems.all.length) && this.$wrapWithLoading(
                this.axios.put(this.batchUrl, {
                    'do': 'move',
                    'currentDirectory': this.currentDirectory,
                    'directory': this.destinationDirectory,
                    'files': this.selectedItems.files,
                    'dirs': this.selectedItems.directories
                })
            ).then(() => {
                let notifyMessage = this.$gettext('Files moved:');
                let itemNameNodes = [];
                forEach(this.selectedItems.all, (item) => {
                    itemNameNodes.push(this.$createElement('div', {}, item.name));
                });

                this.$notifySuccess(itemNameNodes, {
                    title: notifyMessage
                });
            }).finally(() => {
                this.close();
                this.$emit('relist');
            });
        },
        enterDirectory (path) {
            this.dirHistory.push(path);
            this.destinationDirectory = path;

            this.$refs.datatable.refresh();
        },
        pageBack: function (e) {
            e.preventDefault();

            this.dirHistory.pop();

            let newDirectory = this.dirHistory.slice(-1)[0];
            if (typeof newDirectory === 'undefined' || null === newDirectory) {
                newDirectory = '';
            }
            this.destinationDirectory = newDirectory;

            this.$refs.datatable.refresh();
        },
        requestConfig (config) {
            config.params.currentDirectory = this.destinationDirectory;
            config.params.csrf = this.csrf;

            return config;
        }
    }
};
</script>
