
import List from './components/List.vue'
import Edit from './components/Edit.vue'
import View from './components/View.vue'


const routes = [
	{ path: '/', component: List },
	{ path: '/view/:id', component: View },
	{ path: '/edit/:id', component: Edit }
]

export default routes