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
            <podcast-form-basic-info
                :form="v$.form"
                :categories-options="categoriesOptions"
                :language-options="languageOptions"
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
import PodcastFormBasicInfo from './PodcastForm/BasicInfo';
import PodcastCommonArtwork from './Common/Artwork';
import mergeExisting from "~/functions/mergeExisting";
import useVuelidate from "@vuelidate/core";

/* TODO Options API */

export default {
    name: 'EditModal',
    components: {PodcastCommonArtwork, PodcastFormBasicInfo},
    mixins: [BaseEditModal],
    props: {
        stationTimeZone: {
            type: String,
            required: true
        },
        languageOptions: {
            type: Object,
            required: true
        },
        categoriesOptions: {
            type: Object,
            required: true
        },
        newArtUrl: {
            type: String,
            required: true
        }
    },
    setup() {
        return {v$: useVuelidate()}
    },
    data() {
        return {
            record: {
                has_custom_art: false,
                art: null,
                links: {}
            },
            form: {
                'title': '',
                'link': '',
                'description': '',
                'language': 'en',
                'author': '',
                'email': '',
                'categories': [],
                'artwork_file': null
            }
        };
    },
    computed: {
        langTitle () {
            return this.isEditMode
                ? this.$gettext('Edit Podcast')
                : this.$gettext('Add Podcast');
        }
    },
    validations: {
        form: {
            'title': {required},
            'link': {},
            'description': {required},
            'language': {required},
            'author': {},
            'email': {},
            'categories': {required},
            'artwork_file': {}
        }
    },
    methods: {
        resetForm () {
            this.record = {
                has_custom_art: false,
                art: null,
                links: {
                    art: null
                }
            };
            this.form = {
                'title': '',
                'link': '',
                'description': '',
                'language': 'en',
                'author': '',
                'email': '',
                'categories': [],
                'artwork_file': null
            };
        },
        populateForm (d) {
            this.record = d;
            this.form = mergeExisting(this.form, d);
        }
    }
};
</script>
