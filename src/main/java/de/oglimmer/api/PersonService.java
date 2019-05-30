package de.oglimmer.api;

import java.sql.SQLException;
import java.util.List;

import javax.enterprise.context.RequestScoped;
import javax.inject.Inject;
import javax.json.Json;
import javax.json.bind.JsonbBuilder;
import javax.ws.rs.Consumes;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.QueryParam;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import de.oglimmer.model.Person;

@RequestScoped
@Path("person")
@Produces({ MediaType.APPLICATION_JSON })
@Consumes({ MediaType.APPLICATION_JSON })
public class PersonService {

	@Inject
	de.oglimmer.service.PersonService service;

	@GET
	@Path("{id}")
	public Response get(@PathParam("id") long id) {
		Person person = service.get(id);
		return Response.ok(JsonbBuilder.create().toJson(person)).build();
	}

	@GET
	public Response list(@QueryParam("surname") String searchSurname, @QueryParam("firstname") String searchFirstname,
			@QueryParam("pageNo") int pageNo, @QueryParam("sortCol") String sortCol,
			@QueryParam("sortOrder") String sortOrder, @QueryParam("sizeOnly") boolean sizeOnly) throws SQLException {
		if (sizeOnly) {
			long size = service.listSize(searchSurname, searchFirstname);
			return Response.ok(Json.createObjectBuilder().add("size", size).build()).build();
		} else {
			if (pageNo < 1) {
				pageNo = 1;
			}
			List<Person> list = service.list(searchSurname, searchFirstname, pageNo, sortCol, sortOrder);
			return Response.ok(JsonbBuilder.create().toJson(list)).build();
		}
	}

	@POST
	public Response save(Person person) {
		service.save(person);
		return Response.ok(JsonbBuilder.create().toJson(person)).build();
	}

}
