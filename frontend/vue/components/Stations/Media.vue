<template>
    <div class="row">
        <div class="col-12">
            <div class="card">
                <b-card-header header-bg-variant="primary-dark">
                    <b-row class="align-items-center">
                        <b-col md="7">
                            <h2 class="card-title">
                                {{ $gettext('Music Files') }}
                            </h2>
                        </b-col>
                        <b-col
                            md="5"
                            class="text-right text-white-50"
                        >
                            <stations-common-quota
                                ref="quota"
                                :quota-url="quotaUrl"
                            />
                        </b-col>
                    </b-row>
                </b-card-header>

                <div
                    v-if="showSftp"
                    class="card-body alert-info d-flex align-items-center"
                    role="alert"
                >
                    <div class="flex-shrink-0 mr-2">
                        <i
                            class="material-icons"
                            aria-hidden="true"
                        >info</i>
                    </div>
                    <div class="flex-fill">
                        <p class="mb-0">
                            {{ $gettext('You can also upload files in bulk via SFTP.') }}
                        </p>
                    </div>
                    <div class="flex-shrink-0 ml-2">
                        <a
                            class="btn btn-sm btn-light"
                            target="_blank"
                            :href="sftpUrl"
                        >
                            {{ $gettext('Manage SFTP Accounts') }}
                        </a>
                    </div>
                </div>

                <div class="card-body">
                    <breadcrumb
                        :current-directory="currentDirectory"
                        @change-directory="changeDirectory"
                    />

                    <file-upload
                        :upload-url="uploadUrl"
                        :search-phrase="searchPhrase"
                        :valid-mime-types="validMimeTypes"
                        :current-directory="currentDirectory"
                        @relist="onTriggerRelist"
                    />

                    <media-toolbar
                        :batch-url="batchUrl"
                        :selected-items="selectedItems"
                        :current-directory="currentDirectory"
                        :supports-immediate-queue="supportsImmediateQueue"
                        :playlists="playlists"
                        @add-playlist="onAddPlaylist"
                        @relist="onTriggerRelist"
                    />
                </div>

                <data-table
                    id="station_media"
                    ref="datatable"
                    selectable
                    paginated
                    select-fields
                    :fields="fields"
                    :api-url="listUrl"
                    :request-config="requestConfig"
                    @row-selected="onRowSelected"
                >
                    <template #cell(path)="row">
                        <div class="d-flex align-items-center">
                            <div class="flex-shrink-0 pr-2">
                                <template v-if="row.item.media.is_playable">
                                    <play-button
                                        :url="row.item.media.links.play"
                                        icon-class="outlined"
                                    />
                                </template>
                                <template v-else>
                                    <span
                                        v-if="row.item.is_dir"
                                        class="file-icon"
                                    >
                                        <icon icon="folder" />
                                    </span>
                                    <span
                                        v-else-if="row.item.is_cover_art"
                                        class="file-icon"
                                    >
                                        <icon icon="photo" />
                                    </span>
                                    <span
                                        v-else
                                        class="file-icon"
                                    >
                                        <icon icon="note" />
                                    </span>
                                </template>
                            </div>

                            <div class="flex-fill">
                                <template v-if="row.item.is_dir">
                                    <a
                                        class="name"
                                        href="#"
                                        :title="row.item.name"
                                        @click.prevent="changeDirectory(row.item.path)"
                                    >
                                        {{ row.item.path_short }}
                                    </a>
                                </template>
                                <template v-else-if="row.item.media.is_playable">
                                    <a
                                        class="name"
                                        :href="row.item.media.links.play"
                                        target="_blank"
                                        :title="row.item.name"
                                    >
                                        {{ row.item.text }}
                                    </a>
                                </template>
                                <template v-else>
                                    <a
                                        class="name"
                                        :href="row.item.links.download"
                                        target="_blank"
                                        :title="row.item.text"
                                    >
                                        {{ row.item.path_short }}
                                    </a>
                                </template>
                                <br>
                                <small v-if="row.item.media.is_playable">{{ row.item.path_short }}</small>
                                <small v-else>{{ row.item.text }}</small>
                            </div>

                            <album-art
                                v-if="row.item.media.art"
                                :src="row.item.media.art"
                                class="flex-shrink-1 pl-2"
                            />
                            <album-art
                                v-else-if="row.item.is_cover_art"
                                :src="row.item.links.download"
                                class="flex-shrink-1 pl-2"
                            />
                        </div>
                    </template>
                    <!-- eslint-disable-next-line -->
                    <template #cell(media.length)="row">
                        {{ row.item.media.length_text }}
                    </template>
                    <template #cell(size)="row">
                        <template v-if="!row.item.size">
&nbsp;
                        </template>
                        <template v-else>
                            {{ formatFileSize(row.item.size) }}
                        </template>
                    </template>
                    <template #cell(playlists)="row">
                        <template
                            v-for="(playlist, index) in row.item.playlists"
                            :key="playlist.id"
                        >
                            <a
                                class="btn-search"
                                href="#"
                                :title="$gettext('View tracks in playlist')"
                                @click.prevent="filter('playlist:'+playlist.name)"
                            >{{ playlist.name }}</a>
                            <span v-if="index+1 < row.item.playlists.length">, </span>
                        </template>
                    </template>
                    <template #cell(commands)="row">
                        <template v-if="row.item.media.links.edit">
                            <b-button
                                size="sm"
                                variant="primary"
                                @click.prevent="edit(row.item.media.links.edit, row.item.media.links.art, row.item.media.links.play, row.item.media.links.waveform)"
                            >
                                {{ $gettext('Edit') }}
                            </b-button>
                        </template>
                        <template v-else>
                            <b-button
                                size="sm"
                                variant="primary"
                                @click.prevent="rename(row.item.path)"
                            >
                                {{ $gettext('Rename') }}
                            </b-button>
                        </template>
                    </template>
                </data-table>
            </div>
        </div>

        <new-directory-modal
            :current-directory="currentDirectory"
            :mkdir-url="mkdirUrl"
            @relist="onTriggerRelist"
        />

        <move-files-modal
            :selected-items="selectedItems"
            :current-directory="currentDirectory"
            :batch-url="batchUrl"
            :list-directories-url="listDirectoriesUrl"
            @relist="onTriggerRelist"
        />

        <rename-modal
            ref="renameModal"
            :rename-url="renameUrl"
            @relist="onTriggerRelist"
        />

        <edit-modal
            ref="editModal"
            :custom-fields="customFields"
            :playlists="playlists"
            @relist="onTriggerRelist"
        />
    </div>
</template>

<script setup>
import DataTable from '~/components/Common/DataTable';
import MediaToolbar from './Media/MediaToolbar';
import Breadcrumb from './Media/Breadcrumb';
import FileUpload from './Media/FileUpload';
import NewDirectoryModal from './Media/NewDirectoryModal';
import MoveFilesModal from './Media/MoveFilesModal';
import RenameModal from './Media/RenameModal';
import EditModal from './Media/EditModal';
import StationsCommonQuota from "~/components/Stations/Common/Quota";
import Icon from '~/components/Common/Icon';
import AlbumArt from '~/components/Common/AlbumArt';
import PlayButton from "~/components/Common/PlayButton";</script>

<script>
import formatFileSize from '~/functions/formatFileSize.js';
import {forEach, map, partition} from 'lodash';
import {DateTime} from 'luxon';
import {useAzuraCast} from "~/vendor/azuracast";

/* TODO Options API */

export default {
    props: {
        listUrl: {
            type: String,
            required: true
        },
        batchUrl: {
            type: String,
            required: true
        },
        uploadUrl: {
            type: String,
            required: true
        },
        listDirectoriesUrl: {
            type: String,
            required: true
        },
        mkdirUrl: {
            type: String,
            required: true
        },
        renameUrl: {
            type: String,
            required: true
        },
        quotaUrl: {
            type: String,
            required: true
        },
        initialPlaylists: {
            type: Array,
            required: false,
            default: () => []
        },
        customFields: {
            type: Array,
            required: false,
            default: () => []
        },
        validMimeTypes: {
            type: Array,
            required: false,
            default: () => []
        },
        stationTimeZone: {
            type: String,
            required: true
        },
        showSftp: {
            type: Boolean,
            default: true
        },
        sftpUrl: {
            type: String,
            required: true
        },
        supportsImmediateQueue: {
            type: Boolean,
            required: true
        }
    },
    data() {
        let fields = [
            {key: 'path', isRowHeader: true, label: this.$gettext('Name'), sortable: true},
            {key: 'media.title', label: this.$gettext('Title'), sortable: true, selectable: true, visible: false},
            {
                key: 'media.artist',
                label: this.$gettext('Artist'),
                sortable: true,
                selectable: true,
                visible: false
            },
            {key: 'media.album', label: this.$gettext('Album'), sortable: true, selectable: true, visible: false},
            {key: 'media.genre', label: this.$gettext('Genre'), sortable: true, selectable: true, visible: false},
            {key: 'media.isrc', label: this.$gettext('ISRC'), sortable: true, selectable: true, visible: false},
            {key: 'media.length', label: this.$gettext('Length'), sortable: true, selectable: true, visible: true}
        ];

        forEach(this.customFields.slice(), (field) => {
            fields.push({
                key: 'media.custom_fields[' + field.id + ']',
                label: field.name,
                sortable: true,
                selectable: true,
                visible: false
            });
        });

        fields.push(
            {key: 'size', label: this.$gettext('Size'), sortable: true, selectable: true, visible: true},
            {
                key: 'timestamp',
                label: this.$gettext('Modified'),
                sortable: true,
                formatter: (value) => {
                    if (!value) {
                        return '';
                    }

                    const {timeConfig} = useAzuraCast();

                    return DateTime.fromSeconds(value).setZone(this.stationTimeZone).toLocaleString(
                        {...DateTime.DATETIME_MED, ...timeConfig}
                    );
                },
                selectable: true,
                visible: true
            },
            {
                key: 'playlists',
                label: this.$gettext('Playlists'),
                sortable: false,
                selectable: true,
                visible: true
            },
            {key: 'commands', label: this.$gettext('Actions'), sortable: false, class: 'shrink'}
        );

        return {
            fields: fields,
            playlists: this.initialPlaylists,
            selectedItems: {
                all: [],
                files: [],
                directories: []
            },
            currentDirectory: '',
            searchPhrase: null
        };
    },
    created() {
        // Load directory from URL hash, if applicable.
        let urlHash = decodeURIComponent(window.location.hash.substring(1).replace(/\+/g, '%20'));

        if ('' !== urlHash) {
            if (this.isFilterString(urlHash)) {
                this.$nextTick(() => {
                    this.onHashChange();
                });
            } else {
                this.currentDirectory = urlHash;
            }
        }

        window.addEventListener('hashchange', this.onHashChange);
    },
    unmounted() {
        window.removeEventListener('hashchange', this.onHashChange);
    },
    methods: {
        formatFileSize(size) {
            return formatFileSize(size);
        },
        onRowSelected(items) {
            let splitItems = partition(items, 'is_dir');

            this.selectedItems = {
                all: items,
                files: map(splitItems[1], 'path'),
                directories: map(splitItems[0], 'path')
            };
        },
        onTriggerNavigate() {
            this.$refs.datatable.navigate();
        },
        onTriggerRelist() {
            this.$refs.quota.update();
            this.$refs.datatable.relist();
        },
        onAddPlaylist(row) {
            this.playlists.push(row);
        },
        onHashChange() {
            // Handle links from the sidebar for special functions.
            let urlHash = decodeURIComponent(window.location.hash.substring(1).replace(/\+/g, '%20'));

            if ('' !== urlHash && this.isFilterString(urlHash)) {
                window.location.hash = '';
                this.filter(urlHash);
            }
        },
        isFilterString(str) {
            return str.substring(0, 9) === 'playlist:' || str.substring(0, 8) === 'special:';
        },
        changeDirectory(newDir) {
            window.location.hash = newDir;

            this.currentDirectory = newDir;
            this.onTriggerNavigate();
        },
        filter(newFilter) {
            this.$refs.datatable.setFilter(newFilter);
        },
        onFiltered(newFilter) {
            this.searchPhrase = newFilter;
        },
        rename(path) {
            this.$refs.renameModal.open(path);
        },
        edit(recordUrl, albumArtUrl, audioUrl, waveformUrl) {
            this.$refs.editModal.open(recordUrl, albumArtUrl, audioUrl, waveformUrl);
        },
        requestConfig(config) {
            config.params.currentDirectory = this.currentDirectory;
            return config;
        }
    }
};
</script>
