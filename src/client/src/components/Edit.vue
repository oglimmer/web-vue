<template>
<div>
	{{$route.params.id}}
	Firstname: <input v-model="data.firstname" /><br/>
	Surname: <input v-model="data.surname" /><br/>
	Street: <input v-model="data.street" /><br/>
	Zip: <input v-model="data.zip" /><br/>
	City: <input v-model="data.city" /><br/>
	Height: <input v-model="data.height" /><br/>
	Birthday: <input v-model="data.birthday" /><br/>

	<button v-on:click="cancel">Cancel</button>
	<button v-on:click="save">Save</button>
</div>
</template>

<script>
import axios from 'axios'

export default {
	name: 'edit',
	components: {
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
				birthday: ""
			}
		}
	},
	mounted() {
	},
	computed: {
	},
	methods: {
		fetchData() {
			const url = location.port == 8081 ? 'http://localhost:8080/vue/resources/person' : 'resources/person'
			axios.get(url, {
				params: {
					surname: this.surname,
					firstname: this.firstname,
					pageNo: this.pageNo,
					sortCol: this.sortCol,
					sortOrder: this.sortOrder
				}
			}).then(response => {
				this.data = response.data
			})
		},
		cancel() {
			this.$router.push({ path: '../' })
		},
		save() {

		}
	}
}
</script>

<style scoped>

</style>
