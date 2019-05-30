package de.oglimmer.service;

import java.sql.SQLException;
import java.util.List;

import javax.annotation.sql.DataSourceDefinition;
import javax.ejb.Stateless;
import javax.ejb.TransactionAttribute;
import javax.ejb.TransactionAttributeType;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.TypedQuery;
import javax.persistence.criteria.CriteriaBuilder;
import javax.persistence.criteria.CriteriaQuery;
import javax.persistence.criteria.JoinType;
import javax.persistence.criteria.Root;

import de.oglimmer.model.Person;

@Stateless
public class PersonService {

	@PersistenceContext
	private EntityManager entityManager;

	@TransactionAttribute(TransactionAttributeType.REQUIRED)
	public void save(Person person) {
		if (person.getId() == null) {
			entityManager.persist(person);
			entityManager.flush();
		} else {
			entityManager.merge(person);
		}
	}

	public List<Person> list(String searchSurname, String searchFirstname, int pageNo, String sortCol, String sortOrder)
			throws SQLException {
		SingleTableQLBuilder ql = SingleTableQLBuilder.table("Person");

		if (searchSurname != null && !searchSurname.isEmpty()) {
			ql.where("surname", "like", searchSurname);
		}
		if (searchFirstname != null && !searchFirstname.isEmpty()) {
			ql.where("firstname", "like", searchFirstname);
		}

		if (sortCol != null && !sortCol.isEmpty()) {
			ql.sort(sortCol, sortOrder);
		}

		TypedQuery<Person> query = entityManager.createQuery(ql.toString(), Person.class);
		ql.setParams(query);
		query.setFirstResult((pageNo - 1) * 10);
		query.setMaxResults(10);
		return query.getResultList();
	}

	public long listSize(String searchSurname, String searchFirstname) throws SQLException {
		SingleTableQLBuilder ql = SingleTableQLBuilder.table("Person");

		ql.select("count(obj)");

		if (searchSurname != null && !searchSurname.isEmpty()) {
			ql.where("surname", "like", searchSurname);
		}
		if (searchFirstname != null && !searchFirstname.isEmpty()) {
			ql.where("firstname", "like", searchFirstname);
		}

		TypedQuery<Long> query = entityManager.createQuery(ql.toString(), Long.class);
		ql.setParams(query);
		return query.getSingleResult();
	}

	public Person get(Long id) {
		return entityManager.find(Person.class, id);
	}

	public Person getFull(Long id) {
		CriteriaBuilder criteriaBuilder = entityManager.getCriteriaBuilder();
		CriteriaQuery<Person> query = criteriaBuilder.createQuery(Person.class);
		Root<Person> root = query.from(Person.class);
		root.fetch("communicationChannels", JoinType.LEFT);
		query.select(root);
		query.where(criteriaBuilder.equal(root.get("id"), id));

		return entityManager.createQuery(query).getSingleResult();
	}

	@TransactionAttribute(TransactionAttributeType.REQUIRED)
	public void deleteObject(long id) {
		Person entity = entityManager.getReference(Person.class, id);
		entityManager.remove(entity);
	}
}