<template>
<div>
	<table>
		<tr>
			<th>
				<SortableHeader displayText="Surname" colName="surname" :onclick="sortButton" :sortCol="sortCol" :sortOrder="sortOrder" />
			</th>
			<th>
				<SortableHeader displayText="Firstname" colName="firstname" :onclick="sortButton" :sortCol="sortCol" :sortOrder="sortOrder" />
			</th>
			<th>
			</th>
		</tr>
		<tr>
			<th><input v-model="surname" /></th>
			<th><input v-model="firstname" /></th>
			<th>
			</th>
		</tr>
		<tr v-for="person in personList" v-bind:key="person.id">
			<td>{{ person.surname }}</td>
			<td>{{ person.firstname }}</td>
			<td><button v-on:click="edit(person.id)">Edit</button></td>
		</tr>
	</table>
	<button v-on:click="searchButton">Search</button>
	<hr />
	<button v-for="i in pagingButtons" v-bind:key="i" v-on:click="pageButton(i)" v-bind:style="{ color: (i==pageNo?'red':'black')}">
		{{i}}
	</button>
	<hr />
	<button v-on:click="newEnityButton">New entity</button>
</div>
</template>

<script>
import axios from 'axios'
import SortableHeader from './SortableHeader.vue'

export default {
	name: 'list',
	components: {
		SortableHeader
	},
	data() {
		return {
			personList: [],
			surname: "",
			firstname: "",
			pageNo: 1,
			sortCol: "",
			sortOrder: "",
			totalSize: 0
		}
	},
	mounted() {
		this.fetchData()
	},
	computed: {
		pagingButtons() {
			const min = Math.max(1, this.pageNo - 3)
			const max = Math.min(this.pageNo + 3, Math.ceil(this.totalSize / 10))
			const retArray = []
			for (var c = min; c <= max; c++ ) {
				retArray.push(c)
			}
			return retArray
		}
	},
	methods: {
		fetchData() {
			const url = location.port == 8081 ? 'http://localhost:8080/vue/resources/person' : 'resources/person'
			const p1 = axios.get(url, {
				params: {
					surname: this.surname,
					firstname: this.firstname,
					sizeOnly: true
				}
			})
			const p2 = axios.get(url, {
				params: {
					surname: this.surname,
					firstname: this.firstname,
					pageNo: this.pageNo,
					sortCol: this.sortCol,
					sortOrder: this.sortOrder
				}
			})
			Promise.all([p1, p2]).then(values => {
				this.totalSize = values[0].data.size
				this.personList = values[1].data
			})
		},
		searchButton() {
			this.pageNo = 1
			this.fetchData()
		},
		pageButton(toPageNo) {
			this.pageNo = toPageNo
			this.fetchData()
		},
		sortButton(toSortCol) {
			if(toSortCol == this.sortCol) {
				if(this.sortOrder == "asc") {
					this.sortOrder = "desc"
				} else {
					this.sortOrder = "asc"
				}
			} else {
				this.sortCol = toSortCol
				this.sortOrder = "asc"
			}
			this.fetchData()
		},
		newEnityButton() {
			this.$router.push({ path: 'edit/new' })
		},
		edit(id) {
			this.$router.push({ path: `edit/${id}` })	
		}
	}
}
</script>

<style scoped>

</style>
