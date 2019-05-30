package de.oglimmer.service;

import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

import javax.persistence.TypedQuery;

public class SingleTableQLBuilder {

	private static class Where {
		public Where(String colName, String op, String param) {
			this.colName = colName;
			this.op = op;
			this.param = param;
		}

		public String colName;
		public String op;
		public String param;
	}

	private String table;
	private String select;
	private String sort;
	private List<Where> where = new ArrayList<>();

	public static SingleTableQLBuilder table(String table) {
		SingleTableQLBuilder newObj = new SingleTableQLBuilder();
		newObj.table = table;
		newObj.select = "obj";
		return newObj;
	}

	public void select(String select) {
		this.select = select;
	}

	public SingleTableQLBuilder where(String colName, String op, String param) {
		where.add(new Where(colName, op, param));
		return this;
	}

	public void setParams(TypedQuery<?> prst) throws SQLException {
		for (Where e : where) {
			prst.setParameter(e.colName, e.param);
		}
	}

	public SingleTableQLBuilder sort(String sortColumn, String sortOrder) {
		sort = "order by obj." + sortColumn + " " + sortOrder;
		return this;
	}

	@Override
	public String toString() {
		String sql = "select " + select + " from " + table + " obj ";
		if (where.size() > 0) {
			sql += " where " + where.stream().map(e -> "obj." + e.colName + " " + e.op + " :" + e.colName)
					.collect(Collectors.joining(" and "));
		}
		if (sort != null) {
			sql += " " + sort;
		}
		return sql;
	}

}
