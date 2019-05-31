<template>
<div>
		Firstname: {{data.firstname}} <br/>
		Surname: {{data.surname}} <br/>
		Street: {{data.street}} <br/>
		Zip: {{data.zip}} <br/>
		City: {{data.city}} <br/>
		Height: {{data.height}} <br/>
		Birthday: {{data.birthday}} <br/>
		<br/>
		Communications:
		<ul>
			<li v-for="row in data.communicationChannels" v-bind:key="row.id">
				{{row.type}} // 
				{{row.data}}
			</li>
		</ul>
		<div v-show="data.communicationChannels.length === 0">No communication details defined</div>
		<br/>
		<button v-on:click="back">Back</button>
		<button v-on:click="edit">Edit</button>
</div>
</template>

<script>
import axios from 'axios'
import dayjs from 'dayjs'
import utcPlugin from 'dayjs/plugin/utc'

dayjs.extend(utcPlugin)

export default {
	name: 'view-component',
	data() {
		return {
			data: {
				communicationChannels: []
			}
		}
	},
	mounted() {
		this.fetchData()
	},
	methods: {
		fetchData() {
			const id = this.$route.params.id
			const url = location.port == 8081 ? `http://localhost:8080/vue/resources/person/${id}` : `resources/person/${id}`
			axios.get(url).then(response => {
				this.data = response.data
			})
		},
		back() {
			this.$router.push({ path: '../' })
		},
		edit() {
			const id = this.$route.params.id
			this.$router.push({ path: `../edit/${id}` })
		}
	}
}
</script>
