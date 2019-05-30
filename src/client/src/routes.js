
import List from './components/List.vue'
import Edit from './components/Edit.vue'


const routes = [
	{ path: '/', component: List },
	{ path: '/edit/:id', component: Edit }
]

export default routes