package org.springframework.samples.petclinic;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Tests d'intégration sur la base PostgreSQL réelle via Testcontainers. Vérifie que
 * Flyway a bien appliqué les migrations V1, V2, V3. Formation DevOps ? Lab 07.
 */
class OwnerRepositoryIntegrationTest extends PostgresIntegrationTest {

	@Autowired
	private JdbcTemplate jdbcTemplate;

	@Test
	void flyway_schema_history_doit_contenir_trois_migrations() {
		Integer count = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM flyway_schema_history WHERE success = true",
				Integer.class);
		assertThat(count).isEqualTo(3);
	}

	@Test
	void table_pets_doit_avoir_colonne_weight_apres_migration_V3() {
		Integer count = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM information_schema.columns "
				+ "WHERE table_name = 'pets' AND column_name = 'weight'", Integer.class);
		assertThat(count).isEqualTo(1);
	}

	@Test
	void table_owners_doit_avoir_index_telephone_apres_migration_V2() {
		Integer count = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM pg_indexes "
				+ "WHERE tablename = 'owners' AND indexname = 'owners_telephone_idx'", Integer.class);
		assertThat(count).isEqualTo(1);
	}

	@Test
	void tables_principales_doivent_exister() {
		Integer count = jdbcTemplate
			.queryForObject(
					"SELECT COUNT(*) FROM information_schema.tables " + "WHERE table_schema = 'public' "
							+ "AND table_name IN ('vets','owners','pets','visits','specialties','types')",
					Integer.class);
		assertThat(count).isEqualTo(6);
	}

}
