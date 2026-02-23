INSERT INTO additional_information (id, name, icon) VALUES ('3f56388a-bb40-4dc9-bc23-9840a26c5a29', 'nTFnNYbEs', 'qXCGyfPERDogYoRPDS');
INSERT INTO additional_information (id, name, icon) VALUES ('659a1e2c-0215-4b73-912a-372039c9cdf9', 'AcJeRLin', 'wIKFMdfoFuwhEah');

INSERT INTO location (id, country, street_number, street) VALUES ('b96b5cc9-a13a-46cb-95aa-919545473bde', 'CzONuFpJRtPv', 3902, 'JdyHPlGDAa');
INSERT INTO location (id, country, street_number, street) VALUES ('5fe3a44e-3c6b-4693-97db-985e9e744a97', 'LEOPEcZnSrGK', 2555, 'grWzLOwHnswH');

INSERT INTO business (id, name, created_at, location_id, number_of_votes, longitude, latitude, type, about, local_currency, average_mark) VALUES ('4e6729a0-219c-4cbf-bb9b-5b3880a609c6', 'JnXLuFtRKT', '2024-10-01 10:28:58', 'b96b5cc9-a13a-46cb-95aa-919545473bde', 954, 284.198357, 771.207984, 'uRInExAbKatKWhR', 'daCZerfaTThnMjJGL', 'bswHsxpQDEgAchmd', 806.036638);
INSERT INTO business (id, name, created_at, location_id, number_of_votes, longitude, latitude, type, about, local_currency, average_mark) VALUES ('9aa4e712-e968-40e4-9bc4-bf8cb6eb6ff1', 'JGCtjYly', '2024-03-17 06:58:22', NULL, 2302, 21.263515, 494.726531, 'lgEHovnpBq', 'LIvDYKxlykpOQpcPV', 'VjZVSEWtoxGwDq', 231.865210);

INSERT INTO additional_information_business (additional_information_id, business_id) VALUES ('659a1e2c-0215-4b73-912a-372039c9cdf9', '4e6729a0-219c-4cbf-bb9b-5b3880a609c6');
INSERT INTO additional_information_business (additional_information_id, business_id) VALUES ('659a1e2c-0215-4b73-912a-372039c9cdf9', '9aa4e712-e968-40e4-9bc4-bf8cb6eb6ff1');

INSERT INTO business_schedule_exception (id, business_id, starts_at, ends_at, type, open_time, close_time, break_start, break_end, reason, created_at) VALUES ('ffa16e1e-c6f7-4374-a5c6-c393afa126e1', '9aa4e712-e968-40e4-9bc4-bf8cb6eb6ff1', '2025-05-10 02:30:17', '2026-01-31 02:01:28', 'CLOSED', '08:32:49', '21:01:03', '20:45:17', '16:35:04', 'IFObpPOaf', '2025-09-30 06:45:15');
INSERT INTO business_schedule_exception (id, business_id, starts_at, ends_at, type, open_time, close_time, break_start, break_end, reason, created_at) VALUES ('0b1cc2c1-b339-4be3-b005-0ebe203a3b70', '9aa4e712-e968-40e4-9bc4-bf8cb6eb6ff1', '2024-12-22 00:00:32', '2025-11-04 11:54:51', 'CLOSED', '00:31:19', '16:17:29', '22:02:30', '13:55:07', 'gboVKHssnWqAI', '2025-05-22 16:39:43');

INSERT INTO business_working_hours (id, business_id, day, is_closed, open_time, close_time, break_start, break_end, created_at, updated_at) VALUES ('b2f990a8-6e9c-4d17-8513-cef98becd53c', '9aa4e712-e968-40e4-9bc4-bf8cb6eb6ff1', 'MON', TRUE, '21:02:59', '06:28:01', '07:08:45', '12:40:44', '2024-09-18 19:30:46', '2026-01-03 13:14:41');
INSERT INTO business_working_hours (id, business_id, day, is_closed, open_time, close_time, break_start, break_end, created_at, updated_at) VALUES ('a9f422c8-ff3a-4774-993c-cbc1a5c4552c', '9aa4e712-e968-40e4-9bc4-bf8cb6eb6ff1', 'SUN', TRUE, '11:39:30', '18:55:56', '16:38:54', '21:20:43', '2025-12-19 09:27:55', '2024-06-03 16:02:47');

INSERT INTO gallery (id, business_id, url, created_at, size, width, height, is_cover, type) VALUES ('64f83239-8c2e-4431-bd26-743dde1f9c8c', '4e6729a0-219c-4cbf-bb9b-5b3880a609c6', 'lbEhMhZLfh', '2025-10-13 08:20:54', 3428, 3802, 1541, FALSE, 'rDczYRGQp');
INSERT INTO gallery (id, business_id, url, created_at, size, width, height, is_cover, type) VALUES ('a84eb91e-315f-4882-8161-773e1242e14c', '4e6729a0-219c-4cbf-bb9b-5b3880a609c6', 'jhvIlkVMugonYSlId', '2025-03-18 15:11:30', 4679, NULL, 2577, TRUE, 'tzNStAjxBMGUasrBYh');

INSERT INTO schema_migrations (version, dirty) VALUES (1899162, FALSE);
INSERT INTO schema_migrations (version, dirty) VALUES (1541176, TRUE);

INSERT INTO service (id, category, business_id, name, color, duration, price) VALUES ('b3193733-de8a-4f65-9043-66ef07dae9c4', 'LzUkYMZyY', '9aa4e712-e968-40e4-9bc4-bf8cb6eb6ff1', 'oWWVDuVjOTstaOZeFV', 'ORANGE', 3116, 3960);
INSERT INTO service (id, category, business_id, name, color, duration, price) VALUES ('f88ff645-e8c6-4d45-95ff-54ac0591d80f', 'MVHNFMrSiF', '9aa4e712-e968-40e4-9bc4-bf8cb6eb6ff1', 'tqMEnZHmtcjh', 'PINK', 4202, 914);

INSERT INTO subscription_plan (id, code, name, is_active, created_at) VALUES ('0d8251ea-7b7c-4ca7-b0ad-ba226b2685a1', 'COYlawzxGxUDsAuQVy', 'MHoDMJqMrb', FALSE, '2025-01-28 00:38:05');
INSERT INTO subscription_plan (id, code, name, is_active, created_at) VALUES ('1cac20b1-0e0b-4ad4-baa7-d7998444f8ef', 'mqWEwwgYZ', 'vsDaWrtpLcLQ', FALSE, '2024-04-27 12:38:13');

INSERT INTO plan_price (id, subscription_plan_id, country_code, currency, billing_period, price_cents, tax_included, valid_from, valid_to) VALUES ('8b1127c6-7182-45aa-830c-6c858061f92d', '0d8251ea-7b7c-4ca7-b0ad-ba226b2685a1', 'huqocGvmaSGvzAcqyV', 'dtBwrkurwfW', 'YEARLY', 580, FALSE, '2024-10-07 20:05:29', '2024-05-15 08:37:21');
INSERT INTO plan_price (id, subscription_plan_id, country_code, currency, billing_period, price_cents, tax_included, valid_from, valid_to) VALUES ('7d2ca183-0fa2-4fe4-a482-3719259db951', '0d8251ea-7b7c-4ca7-b0ad-ba226b2685a1', 'BCNtFuoZFk', 'ibiXdzZzc', 'MONTHLY', 3528, TRUE, '2025-12-09 08:44:32', '2024-07-02 19:03:42');

INSERT INTO price_adjustment_rule (id, plan_id, country_code, billing_period, business_id, type, value, valid_from, valid_to, priority, created_at) VALUES ('f556e1a6-d7bc-43a6-a2f6-b667e963925d', '1cac20b1-0e0b-4ad4-baa7-d7998444f8ef', 'zkuvCfkXLvUTNN', 'MONTHLY', '9aa4e712-e968-40e4-9bc4-bf8cb6eb6ff1', 'AMOUNT_DISCOUNT', 3858, '2024-07-06 22:10:17', '2025-12-04 09:47:17', 1938, '2024-07-13 15:20:55');
INSERT INTO price_adjustment_rule (id, plan_id, country_code, billing_period, business_id, type, value, valid_from, valid_to, priority, created_at) VALUES ('8917045b-fd48-4710-b64d-799f6550e000', '0d8251ea-7b7c-4ca7-b0ad-ba226b2685a1', 'YbeyRETnIwxhV', NULL, '9aa4e712-e968-40e4-9bc4-bf8cb6eb6ff1', 'PERCENT_DISCOUNT', 2252, '2025-09-13 17:17:11', '2024-06-17 14:03:18', 4520, '2025-02-27 21:20:00');

INSERT INTO "user" (id, name, avatar, password_hash, email, phone_number, created_at, registration_way, status, location_id, language) VALUES ('e910c6e2-d495-46de-8cd5-052c0ab6af4c', 'niqGrHaGWycc', 'szegXivjKoaCGJ', 'PrgJTThKiYMilUpDi', 'zxQbrhpTiZmsQQVjo', 'YucbImfbvk', '2025-03-26 08:04:36', 'PMyRAVEiutJ', 'DELETED', '5fe3a44e-3c6b-4693-97db-985e9e744a97', 'ocLhdgoKUbtol');
INSERT INTO "user" (id, name, avatar, password_hash, email, phone_number, created_at, registration_way, status, location_id, language) VALUES ('295cbd93-04cd-429b-b111-d94ec16e9de0', 'UQzBAzZGJT', 'FZUovSjWAWFbNudk', 'sOGxUTIChpLTZCmJ', 'jnOSNfPBerAyh', 'MPKAJjWuoxKfKu', '2025-08-12 10:08:52', 'KjmdOFSGyV', 'DELETED', 'b96b5cc9-a13a-46cb-95aa-919545473bde', 'yldvdxKVcSzzaa');

INSERT INTO business_client (id, user_id, business_id, created_at) VALUES ('e7bd158e-2210-4ff1-800d-09251a1a176a', 'e910c6e2-d495-46de-8cd5-052c0ab6af4c', '4e6729a0-219c-4cbf-bb9b-5b3880a609c6', '2025-04-14 03:37:12');
INSERT INTO business_client (id, user_id, business_id, created_at) VALUES ('55e21329-22b3-40cd-bd9a-e878f15baa00', '295cbd93-04cd-429b-b111-d94ec16e9de0', '9aa4e712-e968-40e4-9bc4-bf8cb6eb6ff1', '2024-05-22 15:28:59');

INSERT INTO barbershop_client_profile (business_client_id, picture, comment, money_generated, like_to_come) VALUES ('e7bd158e-2210-4ff1-800d-09251a1a176a', 'JmePqkGFnhWGEG', 'lUDwgZCcEwdxZ', 3572, '10:49:27');
INSERT INTO barbershop_client_profile (business_client_id, picture, comment, money_generated, like_to_come) VALUES ('55e21329-22b3-40cd-bd9a-e878f15baa00', 'UTCoRVxrl', 'ZFuAELqCzFhNXMG', 4356, '04:51:55');

INSERT INTO business_subscription (id, business_id, plan_id, billing_period, payer_user_id, status, current_period_start, current_period_end, auto_renew, provider, created_at, updated_at) VALUES ('d4a082eb-a893-49b3-a356-063dcf33d5b5', '9aa4e712-e968-40e4-9bc4-bf8cb6eb6ff1', '1cac20b1-0e0b-4ad4-baa7-d7998444f8ef', 'MONTHLY', NULL, 'PAST_DUE', '2024-06-28 04:09:23', '2025-11-04 04:20:40', FALSE, 'UsIisYGMRCkv', '2024-12-01 00:07:22', '2025-06-02 08:51:46');
INSERT INTO business_subscription (id, business_id, plan_id, billing_period, payer_user_id, status, current_period_start, current_period_end, auto_renew, provider, created_at, updated_at) VALUES ('1221f361-a9f4-4f47-8c77-37828511aecd', '9aa4e712-e968-40e4-9bc4-bf8cb6eb6ff1', '1cac20b1-0e0b-4ad4-baa7-d7998444f8ef', 'YEARLY', '295cbd93-04cd-429b-b111-d94ec16e9de0', 'CANCELED', '2024-05-27 15:33:07', '2025-04-06 18:58:15', FALSE, 'eNZbsUlzkAnxX', '2024-11-19 08:44:29', '2025-08-18 20:22:28');

INSERT INTO client_service_variant (id, business_client_id, service_id, name_of_service, photo, notes, average_duration_minutes, is_active, created_at, updated_at) VALUES ('08166e1a-0627-42a9-9f41-741e0428db45', 'e7bd158e-2210-4ff1-800d-09251a1a176a', 'f88ff645-e8c6-4d45-95ff-54ac0591d80f', 'DpyzqYvvPTPQsnyZvC', 'DteQkKKgKDJQgIvIJ', 'qYOBGkTiLbf', 4219, FALSE, '2024-04-08 03:03:00', '2025-02-01 03:40:26');
INSERT INTO client_service_variant (id, business_client_id, service_id, name_of_service, photo, notes, average_duration_minutes, is_active, created_at, updated_at) VALUES ('8d7a4f10-a5bb-4cb9-a746-e3226bb8ab23', 'e7bd158e-2210-4ff1-800d-09251a1a176a', 'f88ff645-e8c6-4d45-95ff-54ac0591d80f', 'dmhJkjbTXUYCQj', 'mgHMQLIvIG', 'ZPskrbSzbDP', 1807, FALSE, '2024-09-15 09:48:02', '2025-11-10 04:37:11');

INSERT INTO payment (id, subscription_id, business_id, payer_user_id, period_start, period_end, base_price_cents, adjustment_amount_cents, final_price_cents, currency, status, paid_at, provider_payment_id, created_at) VALUES ('74024358-7575-4ab9-8579-910d69c3f2d8', 'd4a082eb-a893-49b3-a356-063dcf33d5b5', '9aa4e712-e968-40e4-9bc4-bf8cb6eb6ff1', '295cbd93-04cd-429b-b111-d94ec16e9de0', '2025-02-12 04:32:52', '2024-05-25 02:36:45', 4882, 4054, 1406, 'hOztkjLrWtix', 'REFUNDED', '2025-06-25 13:17:58', 'kHaVMbugzETJA', '2025-07-28 13:44:35');
INSERT INTO payment (id, subscription_id, business_id, payer_user_id, period_start, period_end, base_price_cents, adjustment_amount_cents, final_price_cents, currency, status, paid_at, provider_payment_id, created_at) VALUES ('d8187f46-a813-47fc-8843-4eac8a20cfcb', 'd4a082eb-a893-49b3-a356-063dcf33d5b5', '4e6729a0-219c-4cbf-bb9b-5b3880a609c6', 'e910c6e2-d495-46de-8cd5-052c0ab6af4c', '2024-11-15 22:03:35', '2024-07-10 09:36:26', 3317, 2292, 3448, 'cscpeVmvFHBR', 'PAID', '2024-03-10 23:15:10', 'ExVRYOWQqTUh', '2024-07-27 23:23:54');

INSERT INTO payment_adjustment_applied (payment_id, rule_id, type, value, amount_cents) VALUES ('d8187f46-a813-47fc-8843-4eac8a20cfcb', '8917045b-fd48-4710-b64d-799f6550e000', 'AMOUNT_DISCOUNT', 4018, 3825);
INSERT INTO payment_adjustment_applied (payment_id, rule_id, type, value, amount_cents) VALUES ('d8187f46-a813-47fc-8843-4eac8a20cfcb', 'f556e1a6-d7bc-43a6-a2f6-b667e963925d', 'AMOUNT_DISCOUNT', 61, 2094);

INSERT INTO review (id, business_id, rating, comment, user_id, updated_at, created_at, status) VALUES ('2b84d7d9-bd78-4222-a492-b9dfc72628fe', '4e6729a0-219c-4cbf-bb9b-5b3880a609c6', 3418, 'HJCuLtiWSUdqq', '295cbd93-04cd-429b-b111-d94ec16e9de0', '2025-03-23 18:36:57', '2026-01-02 08:10:21', NULL);
INSERT INTO review (id, business_id, rating, comment, user_id, updated_at, created_at, status) VALUES ('5151034c-22cd-40b1-b56e-42d03ad5d839', '4e6729a0-219c-4cbf-bb9b-5b3880a609c6', 1169, 'vkutWYgBX', 'e910c6e2-d495-46de-8cd5-052c0ab6af4c', '2024-05-01 15:35:04', '2025-04-10 06:59:53', 'sTrKKIJQ');

INSERT INTO worker (id, role, user_id, business_id, is_working, created_at, picture) VALUES ('4cd9fde5-f0c5-4dbb-81e9-3110615ca25b', 'WORKER', 'e910c6e2-d495-46de-8cd5-052c0ab6af4c', '4e6729a0-219c-4cbf-bb9b-5b3880a609c6', FALSE, '2024-08-23 20:39:36', 'HCnHicBtlBOWNsx');
INSERT INTO worker (id, role, user_id, business_id, is_working, created_at, picture) VALUES ('ff73c238-db04-4349-83bc-6f055768247b', 'ADMIN', 'e910c6e2-d495-46de-8cd5-052c0ab6af4c', '4e6729a0-219c-4cbf-bb9b-5b3880a609c6', TRUE, '2025-03-02 05:09:53', 'MzvhHiGlgyEIsh');

INSERT INTO visit (id, business_id, business_client_id, worker_id, started_at, end_at, status, note, created_at, updated_at) VALUES ('73c79969-fe3a-4928-8b37-13d3cd0b7926', '4e6729a0-219c-4cbf-bb9b-5b3880a609c6', 'e7bd158e-2210-4ff1-800d-09251a1a176a', 'ff73c238-db04-4349-83bc-6f055768247b', '2024-10-23 05:38:23', '2025-11-01 15:18:04', 'NO_SHOW', 'mnkDAtyrnC', '2025-10-09 14:04:22', '2025-04-06 01:53:10');
INSERT INTO visit (id, business_id, business_client_id, worker_id, started_at, end_at, status, note, created_at, updated_at) VALUES ('29780d35-8a9e-4616-9c54-df8c06158744', '4e6729a0-219c-4cbf-bb9b-5b3880a609c6', 'e7bd158e-2210-4ff1-800d-09251a1a176a', '4cd9fde5-f0c5-4dbb-81e9-3110615ca25b', '2024-10-13 22:44:43', '2024-07-30 22:52:35', 'PENDING', 'YhifsEHetZwyWwlb', '2026-01-08 02:12:42', '2025-12-08 22:40:59');

INSERT INTO visit_service_item (id, visit_id, service_id, client_service_variant_id, note, started_at, end_at, price_snapshot, real_duration_of_service) VALUES ('39efe5f0-c16a-4660-8dcc-a9bae1dad998', '73c79969-fe3a-4928-8b37-13d3cd0b7926', 'b3193733-de8a-4f65-9043-66ef07dae9c4', NULL, 'CEhbHWqduMdyqeVV', '02:51:10', NULL, 2803, 523);
INSERT INTO visit_service_item (id, visit_id, service_id, client_service_variant_id, note, started_at, end_at, price_snapshot, real_duration_of_service) VALUES ('2cd7af7c-12c0-4db5-b57d-4f3de122692f', '73c79969-fe3a-4928-8b37-13d3cd0b7926', 'f88ff645-e8c6-4d45-95ff-54ac0591d80f', '08166e1a-0627-42a9-9f41-741e0428db45', 'RZnGbnHCLEF', '22:22:54', '17:52:33', 4458, 637);

INSERT INTO worker_availability (id, worker_id, business_id, type, weekday, date, start_time, end_time, created_at) VALUES ('63d6e6f6-5eb8-4192-a2e2-25c7d3046c74', 'ff73c238-db04-4349-83bc-6f055768247b', '9aa4e712-e968-40e4-9bc4-bf8cb6eb6ff1', 'WEEKLY_TEMPLATE', 'TUE', NULL, '16:56:55', '07:06:15', '2025-11-13 15:25:45');
INSERT INTO worker_availability (id, worker_id, business_id, type, weekday, date, start_time, end_time, created_at) VALUES ('b532f5d4-88c2-4575-8127-d411008c2488', 'ff73c238-db04-4349-83bc-6f055768247b', '9aa4e712-e968-40e4-9bc4-bf8cb6eb6ff1', 'ONE_OFF_SHIFT', 'SAT', '2022-02-19', '19:57:47', '08:20:35', '2025-01-10 23:38:05');

INSERT INTO worker_service (id, worker_id, service_id, is_enabled, created_at) VALUES ('19c8143d-3ca6-451b-8a17-3522f536c4fe', '4cd9fde5-f0c5-4dbb-81e9-3110615ca25b', 'b3193733-de8a-4f65-9043-66ef07dae9c4', FALSE, '2025-03-25 11:35:47');
INSERT INTO worker_service (id, worker_id, service_id, is_enabled, created_at) VALUES ('8e5e0a3c-119e-4302-b892-791873b1589e', 'ff73c238-db04-4349-83bc-6f055768247b', 'f88ff645-e8c6-4d45-95ff-54ac0591d80f', TRUE, '2025-02-22 06:37:12');

