<template>
    <modal-form
        ref="modal"
        :loading="loading"
        :title="langTitle"
        :error="error"
        :disable-save-button="v$.form.$invalid"
        @submit="doSubmit"
        @hidden="clearContents"
    >
        <b-tabs
            content-class="mt-3"
            pills
        >
            <episode-form-basic-info :form="v$.form" />

            <episode-form-media
                v-model="v$.form.media_file.$model"
                :record-has-media="record.has_media"
                :new-media-url="newMediaUrl"
                :edit-media-url="record.links.media"
                :download-url="record.links.download"
            />

            <podcast-common-artwork
                v-model="v$.form.artwork_file.$model"
                :artwork-src="record.art"
                :new-art-url="newArtUrl"
                :edit-art-url="record.links.art"
            />
        </b-tabs>
    </modal-form>
</template>

<script>
import {required} from '@vuelidate/validators';
import BaseEditModal from '~/components/Common/BaseEditModal';
import EpisodeFormBasicInfo from './EpisodeForm/BasicInfo';
import PodcastCommonArtwork from './Common/Artwork';
import EpisodeFormMedia from './EpisodeForm/Media';
import {DateTime} from 'luxon';
import mergeExisting from "~/functions/mergeExisting";
import useVuelidate from "@vuelidate/core";

/* TODO Options API */

export default {
    name: 'EditModal',
    components: {EpisodeFormMedia, PodcastCommonArtwork, EpisodeFormBasicInfo},
    mixins: [BaseEditModal],
    props: {
        stationTimeZone: {
            type: String,
            required: true
        },
        locale: {
            type: String,
            required: true
        },
        podcastId: {
            type: String,
            required: true
        },
        newArtUrl: {
            type: String,
            required: true
        },
        newMediaUrl: {
            type: String,
            required: true
        }
    },
    setup() {
        return {v$: useVuelidate()}
    },
    data() {
        return {
            uploadPercentage: null,
            record: {
                has_custom_art: false,
                art: null,
                has_media: false,
                media: null,
                links: {},
                artwork_file: null,
                media_file: null
            },
        };
    },
    computed: {
        langTitle () {
            return this.isEditMode
                ? this.$gettext('Edit Episode')
                : this.$gettext('Add Episode');
        }
    },
    validations: {
        form: {
            'title': { required },
            'link': {},
            'description': { required },
            'publish_date': {},
            'publish_time': {},
            'explicit': {},
            'artwork_file': {},
            'media_file': {}
        }
    },
    methods: {
        resetForm () {
            this.uploadPercentage = null;
            this.record = {
                has_custom_art: false,
                art: null,
                has_media: false,
                media: null,
                links: {
                    art: null,
                    media: null
                }
            };
            this.form = {
                'title': '',
                'link': '',
                'description': '',
                'publish_date': '',
                'publish_time': '',
                'explicit': false,
                'artwork_file': null,
                'media_file': null
            };
        },
        populateForm (d) {
            let publishDate = '';
            let publishTime = '';

            if (d.publish_at !== null) {
                let publishDateTime = DateTime.fromSeconds(d.publish_at);
                publishDate = publishDateTime.toISODate();
                publishTime = publishDateTime.toISOTime({
                    suppressMilliseconds: true,
                    includeOffset: false
                });
            }

            this.record = mergeExisting(this.record, d);
            this.form = mergeExisting(this.form, {
                ...d,
                publish_date: publishDate,
                publish_time: publishTime
            });
        },
        getSubmittableFormData() {
            let modifiedForm = this.form;

            if (modifiedForm.publish_date.length > 0 && modifiedForm.publish_time.length > 0) {
                let publishDateTimeString = modifiedForm.publish_date + 'T' + modifiedForm.publish_time;
                let publishDateTime = DateTime.fromISO(publishDateTimeString);

                modifiedForm.publish_at = publishDateTime.toSeconds();
            }

            return modifiedForm;
        },
    }
};
</script>
