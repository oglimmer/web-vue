package de.oglimmer.service;

import java.util.List;

import javax.annotation.sql.DataSourceDefinition;
import javax.ejb.Stateless;
import javax.ejb.TransactionAttribute;
import javax.ejb.TransactionAttributeType;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.TypedQuery;

import de.oglimmer.model.CommunicationChannel;


@Stateless
public class CommunicationChannelService {

	@PersistenceContext
	private EntityManager entityManager;

	@TransactionAttribute(TransactionAttributeType.REQUIRED)
	public void save(List<CommunicationChannel> items) {
		items.forEach(cc -> {
			if (cc.getId() == null) {
				entityManager.persist(cc);
				entityManager.flush();
			} else {
				entityManager.merge(cc);
			}
		});
	}

	public List<CommunicationChannel> getByPerson(Long id) {
		TypedQuery<CommunicationChannel> query = entityManager.createQuery(
				"SELECT obj FROM CommunicationChannel obj WHERE obj.person.id = :person_id",
				CommunicationChannel.class);
		query.setParameter("person_id", id);
		return query.getResultList();
	}

}
