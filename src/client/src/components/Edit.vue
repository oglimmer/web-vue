<template>
<div>
	<div id="editpage1" v-show="page === 'page1'">
		Firstname: <input v-model="data.firstname" /> <span v-show="err.firstname">{{err.firstname}}</span><br/>
		Surname: <input v-model="data.surname" /> <span v-show="err.surname">{{err.surname}}</span><br/>
		Street: <input v-model="data.street" /><br/>
		Zip: <input v-model="data.zip" /><br/>
		City: <input v-model="data.city" /><br/>
		Height: <input v-model="data.height" /> <span v-show="err.height">{{err.height}}</span><br/>
		Birthday: <datepicker v-model="data.birthday" format="dd.MM.yyyy" :use-utc="true" :clear-button="true"></datepicker> <span v-show="err.birthday">{{err.birthday}}</span><br/>

		<button v-on:click="back">Cancel</button>
		<button v-on:click="save">Save</button>
		<button v-on:click="toPage2">Next</button>
	</div>
	<div id="editpage2" v-show="page === 'page2'">

		<table>
			<tr v-for="row in data.communicationChannels" v-bind:key="row.id">
				<td><input v-model="row.type" /></td>
				<td><input v-model="row.data" /></td>
			</tr>
		</table>
		
		<button v-on:click="back">Cancel</button>
		<button v-on:click="addRow">Add row</button>
		<button v-on:click="save">Save</button>
		<button v-on:click="toPage1">Back</button>
	</div>
</div>
</template>

<script>
import axios from 'axios'
import Datepicker from 'vuejs-datepicker'
import dayjs from 'dayjs'
import utcPlugin from 'dayjs/plugin/utc'

dayjs.extend(utcPlugin)

const prepareForRest = (obj) =>
  Object.keys(obj)
    .filter(k => obj[k] !== null && obj[k] !== undefined && obj[k] != '')
    .reduce((newObj, k) =>
      (obj[k] instanceof Date ? Object.assign(newObj, {[k]: dayjs(obj[k]).utc().format('YYYY-MM-DD') }) :
      (typeof obj[k] === 'object' && !Array.isArray(obj[k]) ?
        Object.assign(newObj, {[k]: prepareForRest(obj[k])}) :
        Object.assign(newObj, {[k]: obj[k]}))),
      {})

export default {
	name: 'edit',
	components: {
		Datepicker
	},
	data() {
		return {
			data: {
				surname: "",
				firstname: "",
				street: "",
				zip: "",
				city: "",
				height: "",
				birthday: "",
				communicationChannels: []
			},
			err: {
			},
			page: "page1"
		}
	},
	mounted() {
		this.fetchData()
	},
	methods: {
		fetchData() {
			const id = this.$route.params.id
			if(id !== 'new') {
				const url = location.port == 8081 ? `http://localhost:8080/vue/resources/person/${id}` : `resources/person/${id}`
				axios.get(url).then(response => {
					this.data = response.data
				})
			}
		},
		back() {
			if(this.data.id) {
				this.$router.push({ path: `../view/${this.data.id}` })
			} else {
				this.$router.push({ path: '../' })
			}
		},
		validate() {
			this.err = {}
			if(!this.data.firstname) this.err.firstname = "Must not be empty!"
			if(!this.data.surname) this.err.surname = "Must not be empty!"
			if(this.data.height && !(/^\d+$/.test(this.data.height))) this.err.height = "Must be a number!"
			return Object.keys(this.err).length < 1
		},
		save() {
			if(this.validate()) {
				const url = location.port == 8081 ? `http://localhost:8080/vue/resources/person` : `resources/person`
				const objToTransRest = prepareForRest(this.data)
				if(objToTransRest.communicationChannels) {
					objToTransRest.communicationChannels = objToTransRest.communicationChannels.filter(e => e.type && e.data)
				}
				axios.post(url, objToTransRest).then(() => this.back())
			}
		},
		addRow() {
			this.data.communicationChannels.push({type: "", data: ""})
		},
		toPage1() {
			this.page = "page1"
		},
		toPage2() {
			this.page = "page2"
		}
	}
}
</script>

<style>
.vdp-datepicker, .vdp-datepicker > div {
	display: inline
}
</style>
