INSERT INTO additional_information (id, name, icon) VALUES ('ef8245fa-db75-4172-88a9-cb12477a2af1', 'EeVUSUTE', 'CXmCvFzXjMY');
INSERT INTO additional_information (id, name, icon) VALUES ('64287a0d-f0a3-4768-81d3-3877e78619c1', 'GzOEeVwERsjg', 'ZpmLsGMATktGQyWuLX');

INSERT INTO location (id, country, street_number, street) VALUES ('d71b988d-fc25-44d6-92cf-c1ff1d268449', 'nxeSWWZQA', 341, 'cBnIwUIBHeTxQU');
INSERT INTO location (id, country, street_number, street) VALUES ('aac9a9e6-4a9d-43ca-a7d8-41fbb65534a3', 'QWlldzmOh', 2284, 'mRJmgkKRazfRf');

INSERT INTO business (id, name, created_at, location_id, number_of_votes, longitude, latitude, type, about, local_currency, average_mark) VALUES ('50b320a1-b6ea-443c-b729-0e239be4375b', 'YNGrxjoHgUYoMdPyI', '2025-03-29 10:50:14', NULL, 401, 591.171037, 590.653874, 'QgFfeWJLiyy', 'ATywsSQFU', 'fHEzveFMaqeQaJot', 399.963964);
INSERT INTO business (id, name, created_at, location_id, number_of_votes, longitude, latitude, type, about, local_currency, average_mark) VALUES ('eaa26178-d8dc-46d8-aeb1-bb48b067eebf', 'yBaKpkljpQgpa', '2024-10-04 12:32:17', 'aac9a9e6-4a9d-43ca-a7d8-41fbb65534a3', 1753, 922.836130, 940.464588, 'mekWfPnhVoRqkBJO', 'TMswFTgKx', 'RjgbztArdsD', 969.592108);

INSERT INTO additional_information_business (additional_information_id, business_id) VALUES ('64287a0d-f0a3-4768-81d3-3877e78619c1', '50b320a1-b6ea-443c-b729-0e239be4375b');
INSERT INTO additional_information_business (additional_information_id, business_id) VALUES ('ef8245fa-db75-4172-88a9-cb12477a2af1', 'eaa26178-d8dc-46d8-aeb1-bb48b067eebf');

INSERT INTO business_schedule_exception (id, business_id, starts_at, ends_at, type, open_time, close_time, break_start, break_end, reason, created_at) VALUES ('aae9728b-fd80-4884-ba66-83021b3c969e', 'eaa26178-d8dc-46d8-aeb1-bb48b067eebf', '2025-07-06 16:52:04', '2024-12-27 04:21:48', 'CLOSED', '08:10:04', '23:09:56', NULL, '11:51:12', 'CcoRPzBTW', '2024-06-21 00:56:37');
INSERT INTO business_schedule_exception (id, business_id, starts_at, ends_at, type, open_time, close_time, break_start, break_end, reason, created_at) VALUES ('c647392c-f62d-42f6-b804-e1f1ba0a4157', '50b320a1-b6ea-443c-b729-0e239be4375b', '2025-07-16 04:35:05', '2024-04-06 10:46:52', 'CLOSED', '13:45:33', '21:44:10', '20:44:31', '06:04:27', 'OBqoUlttCHrsR', '2025-08-06 16:58:25');

INSERT INTO business_working_hours (id, business_id, day, is_closed, open_time, close_time, break_start, break_end, created_at, updated_at) VALUES ('413cce04-faec-4f86-8933-57d6a645ecda', 'eaa26178-d8dc-46d8-aeb1-bb48b067eebf', 'SUN', FALSE, '15:05:42', '08:13:03', NULL, '19:00:47', '2024-08-06 16:16:09', '2025-04-07 00:37:59');
INSERT INTO business_working_hours (id, business_id, day, is_closed, open_time, close_time, break_start, break_end, created_at, updated_at) VALUES ('1ccbfc6c-f561-43ee-9cb9-06f2441d587b', 'eaa26178-d8dc-46d8-aeb1-bb48b067eebf', 'SAT', TRUE, '05:48:18', '20:57:13', '06:36:08', '02:23:06', '2024-07-08 22:12:02', '2024-05-05 21:37:26');

INSERT INTO gallery (id, business_id, url, created_at, size, width, height, is_cover, type) VALUES ('9f9ef711-643b-4abe-bcc2-9bbdad69f880', 'eaa26178-d8dc-46d8-aeb1-bb48b067eebf', 'IfWTmrTquKgnhEmM', '2024-06-03 06:36:13', 1813, 36, 4628, TRUE, 'kvYlHQqIf');
INSERT INTO gallery (id, business_id, url, created_at, size, width, height, is_cover, type) VALUES ('d8c27e81-fc96-4fda-9234-dfea3ce2517d', 'eaa26178-d8dc-46d8-aeb1-bb48b067eebf', 'TSOlInWQCwFZEJJ', '2025-09-03 05:47:26', 1865, 1833, 1735, FALSE, NULL);

INSERT INTO schema_migrations (version, dirty) VALUES (748406, TRUE);
INSERT INTO schema_migrations (version, dirty) VALUES (1824966, FALSE);

INSERT INTO service (id, category, business_id, name, color, duration, price) VALUES ('b509fc76-851e-477f-8b20-ba9106335e8d', 'wWdOQdvtFwHEZ', 'eaa26178-d8dc-46d8-aeb1-bb48b067eebf', 'MoLgFeqlQIebBOy', 'RED', 28, 3064);
INSERT INTO service (id, category, business_id, name, color, duration, price) VALUES ('e0dac6ee-7924-4f65-b443-c84519d63a15', 'gsdALbzjtTPUTS', 'eaa26178-d8dc-46d8-aeb1-bb48b067eebf', 'owXDQdwzmcXcO', 'BROWN', 3006, 257);

INSERT INTO subscription_plan (id, code, name, is_active, created_at) VALUES ('ab5b8bc5-1f99-4dd0-8351-f47532810dd9', 'TxjdlrfZ', 'iSSRQPzhhNvtP', FALSE, '2025-02-10 20:57:34');
INSERT INTO subscription_plan (id, code, name, is_active, created_at) VALUES ('c8d5b4a4-fd71-40dd-aacb-f69e23d86ee8', 'tMcdzTgHiZlMRA', 'JOoGlHTqAlUFhv', TRUE, '2024-11-04 18:01:22');

INSERT INTO plan_price (id, subscription_plan_id, country_code, currency, billing_period, price_cents, tax_included, valid_from, valid_to) VALUES ('7695645e-0623-4734-a57c-d0e23beab31f', 'c8d5b4a4-fd71-40dd-aacb-f69e23d86ee8', 'npzXeFRNIhxgsfAIB', 'IpscPHRDnDKxeumUQh', 'YEARLY', 1987, TRUE, '2024-04-20 23:03:03', '2025-02-07 12:21:53');
INSERT INTO plan_price (id, subscription_plan_id, country_code, currency, billing_period, price_cents, tax_included, valid_from, valid_to) VALUES ('620a3817-47a4-4671-9fe1-233024516bc6', 'ab5b8bc5-1f99-4dd0-8351-f47532810dd9', 'dcDnPzhPKkGvkmGy', 'AqRaWCHFPHRCjM', 'MONTHLY', 4914, FALSE, '2025-04-06 10:24:46', '2024-04-16 23:01:13');

INSERT INTO price_adjustment_rule (id, plan_id, country_code, billing_period, business_id, type, value, valid_from, valid_to, priority, created_at) VALUES ('69b7e6f4-f548-4176-bc58-b0b117d6bdfc', NULL, 'NEquimlDiqWTIygJ', 'MONTHLY', NULL, 'AMOUNT_DISCOUNT', 1911, '2024-09-17 04:52:48', '2024-05-22 06:58:04', 3336, '2025-08-30 13:07:28');
INSERT INTO price_adjustment_rule (id, plan_id, country_code, billing_period, business_id, type, value, valid_from, valid_to, priority, created_at) VALUES ('efc22bab-9e81-4657-87a7-f0a309c23429', 'c8d5b4a4-fd71-40dd-aacb-f69e23d86ee8', 'OLkaqWxqLIBSrHWM', NULL, 'eaa26178-d8dc-46d8-aeb1-bb48b067eebf', 'FIXED_PRICE', 3522, '2025-06-13 23:34:42', '2024-06-02 22:50:22', 4074, '2024-05-11 20:54:12');

INSERT INTO "user" (id, name, avatar, password_hash, email, phone_number, created_at, registration_way, status, location_id, language) VALUES ('8cf02b3f-aee6-446a-8f4f-d51fd6a02637', 'hAvRDXcvncIboO', NULL, 'HnFmVXyOvKtZ', 'EeVMwSMieLQs', 'YviVqIlSVATOCNwznx', '2026-01-15 06:32:35', 'irlmkpqkLuxFWNpE', 'BANNED', 'd71b988d-fc25-44d6-92cf-c1ff1d268449', NULL);
INSERT INTO "user" (id, name, avatar, password_hash, email, phone_number, created_at, registration_way, status, location_id, language) VALUES ('c4afdf26-0014-4f3c-a411-8d04a7569b7b', 'XgChSCinGDOpkjWpa', 'njebBYZvBwAAZr', 'RSgoqDGzGQBzUMkPC', 'POecnQmqofJKjJpI', 'PxXBuISqsHZvYL', '2024-11-22 17:03:13', 'vnTjJuAEYULHDZTw', 'ACTIVE', NULL, 'cgDIbghoQiYTsCjCFw');

INSERT INTO business_client (id, user_id, business_id, created_at) VALUES ('e973e2e9-f7ee-4ee4-a4ba-afda23586049', '8cf02b3f-aee6-446a-8f4f-d51fd6a02637', 'eaa26178-d8dc-46d8-aeb1-bb48b067eebf', '2024-05-05 15:16:31');
INSERT INTO business_client (id, user_id, business_id, created_at) VALUES ('c6c9129f-21b4-4195-a114-52783067c697', 'c4afdf26-0014-4f3c-a411-8d04a7569b7b', '50b320a1-b6ea-443c-b729-0e239be4375b', '2025-01-29 15:33:53');

INSERT INTO barbershop_client_profile (business_client_id, picture, comment, money_generated, like_to_come) VALUES ('e973e2e9-f7ee-4ee4-a4ba-afda23586049', 'kqeGaRLYuth', 'JJTUZPVmkpZSgKc', 3853, '07:48:36');
INSERT INTO barbershop_client_profile (business_client_id, picture, comment, money_generated, like_to_come) VALUES ('c6c9129f-21b4-4195-a114-52783067c697', 'dykhxwnKjU', 'CYvjFQLAPn', 2750, '05:06:57');

INSERT INTO business_subscription (id, business_id, plan_id, billing_period, payer_user_id, status, current_period_start, current_period_end, auto_renew, provider, created_at, updated_at) VALUES ('c4b706ee-06a6-4eaa-85b2-80b358457025', '50b320a1-b6ea-443c-b729-0e239be4375b', 'c8d5b4a4-fd71-40dd-aacb-f69e23d86ee8', 'MONTHLY', '8cf02b3f-aee6-446a-8f4f-d51fd6a02637', 'ACTIVE', '2024-06-15 19:12:22', '2025-01-08 01:45:19', FALSE, 'ZjzNiVHQlk', '2025-03-24 07:38:26', '2025-03-17 21:38:01');
INSERT INTO business_subscription (id, business_id, plan_id, billing_period, payer_user_id, status, current_period_start, current_period_end, auto_renew, provider, created_at, updated_at) VALUES ('9603e387-db3f-4796-8266-eac33cb209d2', 'eaa26178-d8dc-46d8-aeb1-bb48b067eebf', 'ab5b8bc5-1f99-4dd0-8351-f47532810dd9', 'YEARLY', '8cf02b3f-aee6-446a-8f4f-d51fd6a02637', 'PAST_DUE', '2024-07-14 22:17:43', '2025-01-15 22:37:15', TRUE, 'rdOoHTPKczbBsll', '2025-09-10 01:46:58', '2024-09-08 23:09:32');

INSERT INTO client_service_variant (id, business_client_id, service_id, name_of_service, photo, notes, average_duration_minutes, is_active, created_at, updated_at) VALUES ('6925dcee-902e-43bc-a954-3dce1be049e2', 'c6c9129f-21b4-4195-a114-52783067c697', 'e0dac6ee-7924-4f65-b443-c84519d63a15', 'VBmBjjWS', 'txbBccMPaE', NULL, 4649, TRUE, '2024-06-29 19:49:16', '2025-10-14 14:22:38');
INSERT INTO client_service_variant (id, business_client_id, service_id, name_of_service, photo, notes, average_duration_minutes, is_active, created_at, updated_at) VALUES ('d9e68c70-28c6-4f19-9fe3-ff2940b0411c', 'e973e2e9-f7ee-4ee4-a4ba-afda23586049', 'e0dac6ee-7924-4f65-b443-c84519d63a15', 'dGaAcjbUyDEJjmxRI', 'oLfuehLO', 'rTUNQymAt', 291, FALSE, '2024-06-09 04:51:08', '2025-10-06 18:40:41');

INSERT INTO payment (id, subscription_id, business_id, payer_user_id, period_start, period_end, base_price_cents, adjustment_amount_cents, final_price_cents, currency, status, paid_at, provider_payment_id, created_at) VALUES ('322a73a1-bff5-4975-a576-894b441b473e', NULL, '50b320a1-b6ea-443c-b729-0e239be4375b', 'c4afdf26-0014-4f3c-a411-8d04a7569b7b', '2025-02-06 20:22:00', '2025-09-05 21:05:45', 657, 1209, 4023, 'hnfgOaaBEoE', 'REFUNDED', '2024-04-19 03:34:10', 'PgmbWmyXWWcU', '2025-05-27 00:08:18');
INSERT INTO payment (id, subscription_id, business_id, payer_user_id, period_start, period_end, base_price_cents, adjustment_amount_cents, final_price_cents, currency, status, paid_at, provider_payment_id, created_at) VALUES ('8eef755e-5d1d-403e-b472-54a442936a39', '9603e387-db3f-4796-8266-eac33cb209d2', 'eaa26178-d8dc-46d8-aeb1-bb48b067eebf', '8cf02b3f-aee6-446a-8f4f-d51fd6a02637', '2025-09-13 17:49:23', '2024-05-07 21:23:25', 1785, 1768, 1933, 'MpRNBwNj', 'REFUNDED', '2025-03-06 19:23:18', 'uymoHcAfLRlYw', '2025-04-19 13:21:57');

INSERT INTO payment_adjustment_applied (payment_id, rule_id, type, value, amount_cents) VALUES ('322a73a1-bff5-4975-a576-894b441b473e', '69b7e6f4-f548-4176-bc58-b0b117d6bdfc', 'FIXED_PRICE', 2238, 3612);
INSERT INTO payment_adjustment_applied (payment_id, rule_id, type, value, amount_cents) VALUES ('8eef755e-5d1d-403e-b472-54a442936a39', '69b7e6f4-f548-4176-bc58-b0b117d6bdfc', 'FIXED_PRICE', 1514, 1512);

INSERT INTO review (id, business_id, rating, comment, user_id, updated_at, created_at, status) VALUES ('33dd613b-2df9-48b3-998b-5304024c22db', 'eaa26178-d8dc-46d8-aeb1-bb48b067eebf', 22, 'ODOReSCVfAiL', 'c4afdf26-0014-4f3c-a411-8d04a7569b7b', '2024-11-20 20:25:55', '2025-10-15 20:33:01', 'NfYEjQXgIVBhrWr');
INSERT INTO review (id, business_id, rating, comment, user_id, updated_at, created_at, status) VALUES ('2a4f4c2c-a74a-426e-b80d-46fded969cc7', 'eaa26178-d8dc-46d8-aeb1-bb48b067eebf', 1758, 'ETuVCFcYBqupDAwwh', '8cf02b3f-aee6-446a-8f4f-d51fd6a02637', '2026-02-05 11:14:15', '2025-09-17 15:22:23', 'UVSGfOkajsUXCl');

INSERT INTO worker (id, role, user_id, business_id, is_working, created_at, picture) VALUES ('9ff9f865-678d-4f71-8397-7af39a3a454b', 'OWNER', 'c4afdf26-0014-4f3c-a411-8d04a7569b7b', '50b320a1-b6ea-443c-b729-0e239be4375b', FALSE, '2025-08-05 04:07:44', 'ENehaPSwRNOUTOjsj');
INSERT INTO worker (id, role, user_id, business_id, is_working, created_at, picture) VALUES ('8d7462c2-4f6a-4c10-952d-26a03c4735a1', 'OWNER', 'c4afdf26-0014-4f3c-a411-8d04a7569b7b', 'eaa26178-d8dc-46d8-aeb1-bb48b067eebf', FALSE, '2025-11-16 01:58:22', 'MTBcaatqc');

INSERT INTO visit (id, business_id, business_client_id, worker_id, started_at, end_at, status, note, created_at, updated_at) VALUES ('e2a43afa-1050-446a-8607-cb07c1a9ce5b', 'eaa26178-d8dc-46d8-aeb1-bb48b067eebf', 'c6c9129f-21b4-4195-a114-52783067c697', '8d7462c2-4f6a-4c10-952d-26a03c4735a1', '2024-12-01 21:13:10', '2024-09-11 15:29:25', 'NO_SHOW', 'oAnlqTKJCITtV', '2025-03-19 10:54:38', '2024-11-02 17:22:15');
INSERT INTO visit (id, business_id, business_client_id, worker_id, started_at, end_at, status, note, created_at, updated_at) VALUES ('1035a075-b002-4e9e-9f42-c26b55eefd3e', 'eaa26178-d8dc-46d8-aeb1-bb48b067eebf', 'e973e2e9-f7ee-4ee4-a4ba-afda23586049', '8d7462c2-4f6a-4c10-952d-26a03c4735a1', '2025-05-31 04:54:02', '2024-08-03 17:37:42', 'PENDING', 'mlOddelWaXA', '2025-05-12 07:41:12', '2024-12-27 00:16:05');

INSERT INTO visit_service_item (id, visit_id, service_id, client_service_variant_id, note, started_at, end_at, price_snapshot, real_duration_of_service) VALUES ('9a4e9442-b0ba-4c0f-8429-eea2d47cfceb', '1035a075-b002-4e9e-9f42-c26b55eefd3e', 'b509fc76-851e-477f-8b20-ba9106335e8d', NULL, 'iGDtEFSJvvpuPKs', '00:52:49', '22:00:37', 706, 2394);
INSERT INTO visit_service_item (id, visit_id, service_id, client_service_variant_id, note, started_at, end_at, price_snapshot, real_duration_of_service) VALUES ('52132acd-d76d-422f-9c51-cc35aa4cd57b', '1035a075-b002-4e9e-9f42-c26b55eefd3e', 'e0dac6ee-7924-4f65-b443-c84519d63a15', 'd9e68c70-28c6-4f19-9fe3-ff2940b0411c', 'SvNnZoHpaFMu', '14:03:57', '11:42:55', 2824, 1804);

INSERT INTO worker_availability (id, worker_id, business_id, type, weekday, date, start_time, end_time, created_at) VALUES ('39dcf50a-e7ea-4877-99e0-5868d8b62873', '9ff9f865-678d-4f71-8397-7af39a3a454b', '50b320a1-b6ea-443c-b729-0e239be4375b', 'ONE_OFF_SHIFT', 'SUN', '2023-02-05', '10:48:57', '10:22:26', '2024-03-29 01:08:19');
INSERT INTO worker_availability (id, worker_id, business_id, type, weekday, date, start_time, end_time, created_at) VALUES ('29b96a8b-b7b4-4ad6-9aae-43904953e17d', '9ff9f865-678d-4f71-8397-7af39a3a454b', 'eaa26178-d8dc-46d8-aeb1-bb48b067eebf', 'ONE_OFF_SHIFT', 'SAT', '2021-08-12', '05:00:09', '10:23:24', '2024-06-04 08:29:25');

INSERT INTO worker_service (id, worker_id, service_id, is_enabled, created_at) VALUES ('43b61c59-a6cb-4a18-b60d-f3d8d920897b', '9ff9f865-678d-4f71-8397-7af39a3a454b', 'b509fc76-851e-477f-8b20-ba9106335e8d', TRUE, '2024-06-03 14:28:40');
INSERT INTO worker_service (id, worker_id, service_id, is_enabled, created_at) VALUES ('696730ea-92ff-415f-b945-774924b0ff56', '8d7462c2-4f6a-4c10-952d-26a03c4735a1', 'b509fc76-851e-477f-8b20-ba9106335e8d', TRUE, '2025-12-17 22:56:35');

