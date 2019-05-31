<template>
  <span>
    {{ displayText }}
	<button v-on:click="onclick(colName)">
		<span v-show="sortCol != colName">-</span>
		<span v-show="sortCol == colName && sortOrder == 'desc'">v</span>
		<span v-show="sortCol == colName && sortOrder == 'asc'">^</span>
	</button>
  </span>
</template>

<script>
export default {
  name: 'SortableHeader',
  props: [ "displayText", "colName", "onclick", "sortCol", "sortOrder" ]
}
</script>
