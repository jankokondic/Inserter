INSERT INTO additional_information (id, name, icon) VALUES ('009ca290-0fc5-44e9-8d0e-0b996245990c', 'XJZODEukuKbM', 'itrFzmdvreq');
INSERT INTO additional_information (id, name, icon) VALUES ('a74e9ad9-f055-4b35-a2d5-2b2f843150c7', 'BOYcBOUYNYQS', 'sBKcAPZufCMJAnNdi');

INSERT INTO location (id, country, street_number, street) VALUES ('ac972cc2-638e-452c-86a0-5c9533b3380a', NULL, 3403, 'ShrjyGlYHixhg');
INSERT INTO location (id, country, street_number, street) VALUES ('3dedb400-761c-486d-ba69-9e83c0a0d981', 'KTYObtPDa', 271, 'AlnldixlPTFFIqDZ');

INSERT INTO business (id, name, created_at, location_id, number_of_votes, longitude, latitude, type, about, local_currency, average_mark) VALUES ('6c29382c-9aa6-4aff-8fe4-f7c21c4d692d', 'TJTUYgGjHEY', '2024-04-11 17:06:30', 'ac972cc2-638e-452c-86a0-5c9533b3380a', 821, 198.385286, 284.290799, 'bsQNFQkt', 'yOSubTEuQyF', 'dKLDqHCWcJ', 689.111139);
INSERT INTO business (id, name, created_at, location_id, number_of_votes, longitude, latitude, type, about, local_currency, average_mark) VALUES ('a092db50-8447-4f5e-bf12-2743ba9211e6', 'LBaNGXtrxrD', '2025-11-02 06:37:56', '3dedb400-761c-486d-ba69-9e83c0a0d981', 4184, 653.203516, 29.143901, 'DKxIsqmNxZFHnSBx', 'uImZKDRLOcDOQgbvL', 'wolJguylkeIz', NULL);

INSERT INTO additional_information_business (additional_information_id, business_id) VALUES ('a74e9ad9-f055-4b35-a2d5-2b2f843150c7', '6c29382c-9aa6-4aff-8fe4-f7c21c4d692d');
INSERT INTO additional_information_business (additional_information_id, business_id) VALUES ('a74e9ad9-f055-4b35-a2d5-2b2f843150c7', 'a092db50-8447-4f5e-bf12-2743ba9211e6');

INSERT INTO business_schedule_exception (id, business_id, starts_at, ends_at, type, open_time, close_time, break_start, break_end, reason, created_at) VALUES ('400dbaf5-7498-4650-80ca-515c6f44dcd9', 'a092db50-8447-4f5e-bf12-2743ba9211e6', '2025-02-05 14:15:40', '2025-08-21 22:47:59', 'CUSTOM_HOURS', '22:29:40', '09:48:40', '15:22:48', '01:18:09', 'AcQIuzzAuunNFe', '2025-11-09 10:45:15');
INSERT INTO business_schedule_exception (id, business_id, starts_at, ends_at, type, open_time, close_time, break_start, break_end, reason, created_at) VALUES ('25ddec1e-911d-40d2-8aac-e3cef509b9b6', 'a092db50-8447-4f5e-bf12-2743ba9211e6', '2025-04-28 19:56:47', '2025-12-05 21:23:19', 'CUSTOM_HOURS', '08:41:56', '14:35:27', '18:04:17', '02:19:33', 'mXiYSmkpiDxc', '2025-01-01 10:13:09');

INSERT INTO business_working_hours (id, business_id, day, is_closed, open_time, close_time, break_start, break_end, created_at, updated_at) VALUES ('9d899866-e9e2-4290-a69e-d144a59f008e', '6c29382c-9aa6-4aff-8fe4-f7c21c4d692d', 'TUE', FALSE, '18:32:12', '10:50:38', '23:39:19', '10:38:33', '2026-02-12 02:26:25', '2025-10-19 00:41:53');
INSERT INTO business_working_hours (id, business_id, day, is_closed, open_time, close_time, break_start, break_end, created_at, updated_at) VALUES ('6829df15-70e8-43a8-b9df-d87770a8277b', 'a092db50-8447-4f5e-bf12-2743ba9211e6', 'TUE', TRUE, '10:43:15', '01:10:52', '08:06:14', '01:30:59', '2025-01-19 13:01:16', '2024-07-22 23:50:24');

INSERT INTO gallery (id, business_id, url, created_at, size, width, height, is_cover, type) VALUES ('fbe5980b-c0f2-4310-abae-2d3dd0867c9b', '6c29382c-9aa6-4aff-8fe4-f7c21c4d692d', 'okbfzXfXcJD', '2024-04-06 02:09:33', 2199, 230, 3914, FALSE, 'KXcftJFeK');
INSERT INTO gallery (id, business_id, url, created_at, size, width, height, is_cover, type) VALUES ('ed5253e0-4676-4820-bf34-599930b84ae5', 'a092db50-8447-4f5e-bf12-2743ba9211e6', 'PAasmGhNt', '2024-07-05 08:35:07', 1990, 607, 1798, FALSE, 'NhbnlXFmb');

INSERT INTO schema_migrations (version, dirty) VALUES (247336, FALSE);
INSERT INTO schema_migrations (version, dirty) VALUES (1390773, TRUE);

INSERT INTO service (id, category, business_id, name, color, duration, price) VALUES ('2886d3af-3349-429f-b5ad-8d47a202f873', 'TfSLribZxl', 'a092db50-8447-4f5e-bf12-2743ba9211e6', 'iprfyHSfSUNMkl', 'BROWN', 4189, 4329);
INSERT INTO service (id, category, business_id, name, color, duration, price) VALUES ('2b7cbac4-917e-47bf-86d0-32a20c4d8249', 'OsepiYAbdVyvdPFlsg', '6c29382c-9aa6-4aff-8fe4-f7c21c4d692d', 'pxJjgWtwwDFYnH', 'ORANGE', 4088, 4823);

INSERT INTO subscription_plan (id, code, name, is_active, created_at) VALUES ('6f28d316-7a4a-4360-aceb-fdd5c5b64254', 'DruCKzOulcNuMzNG', 'iVzowQzLgt', FALSE, '2024-08-16 17:49:29');
INSERT INTO subscription_plan (id, code, name, is_active, created_at) VALUES ('40985e49-2c6b-42ff-b007-ae08706a5905', 'OHFuPdHEVuM', 'bipCSpaqkBXTCUeNDi', FALSE, '2024-12-19 06:44:45');

INSERT INTO plan_price (id, subscription_plan_id, country_code, currency, billing_period, price_cents, tax_included, valid_from, valid_to) VALUES ('a956e465-8c9c-4957-80f8-afb33c6190d1', '6f28d316-7a4a-4360-aceb-fdd5c5b64254', 'OnvPLvGZ', 'HorkZegTQU', 'MONTHLY', 79, TRUE, '2024-04-25 20:02:27', '2025-11-28 15:20:00');
INSERT INTO plan_price (id, subscription_plan_id, country_code, currency, billing_period, price_cents, tax_included, valid_from, valid_to) VALUES ('c5c1bed4-3516-4f77-9d4f-45b67a506d00', '6f28d316-7a4a-4360-aceb-fdd5c5b64254', 'uXsDDSpczW', 'bUQulZhNHuu', 'MONTHLY', 4037, TRUE, '2025-09-05 22:25:22', '2025-11-22 01:18:54');

INSERT INTO price_adjustment_rule (id, plan_id, country_code, billing_period, business_id, type, value, valid_from, valid_to, priority, created_at) VALUES ('e0363049-a6e1-44b3-af1c-0ec63f4cc9f2', '40985e49-2c6b-42ff-b007-ae08706a5905', 'QbqIQvCQtrvKB', 'YEARLY', NULL, 'AMOUNT_DISCOUNT', 1562, '2025-05-07 20:47:49', '2026-01-18 09:50:00', 4993, '2024-12-04 02:53:21');
INSERT INTO price_adjustment_rule (id, plan_id, country_code, billing_period, business_id, type, value, valid_from, valid_to, priority, created_at) VALUES ('c1cbe7f6-efd6-4158-90d2-5824f8137a6b', '40985e49-2c6b-42ff-b007-ae08706a5905', 'igMCruBfVseLGZhrE', 'YEARLY', '6c29382c-9aa6-4aff-8fe4-f7c21c4d692d', 'AMOUNT_DISCOUNT', 2543, '2025-05-30 11:17:40', '2025-04-24 19:49:47', 537, '2024-08-15 16:47:32');

INSERT INTO "user" (id, name, avatar, password_hash, email, phone_number, created_at, registration_way, status, location_id, language) VALUES ('59390cb6-203a-408e-93f2-4f1efbdfe5ef', 'bvvsElQKVrHbMP', 'ZmOGCdrm', 'PEFlwCbV', 'OMtCngGGirB', 'laFoRgCEstuQXtNs', '2025-08-04 06:58:30', 'LvRjdpFkCdOOwKmX', 'BANNED', NULL, 'yTFctdfsRzxOQ');
INSERT INTO "user" (id, name, avatar, password_hash, email, phone_number, created_at, registration_way, status, location_id, language) VALUES ('dd6d6340-d919-46f7-b999-5b24be7627ff', 'IRkzWnAEoGYPGwlFe', 'axGedijCIEubh', 'BBZaOUkjFZTEKLbK', 'UFzfWgTuLsSpJ', NULL, '2026-01-07 16:33:41', NULL, 'ACTIVE', '3dedb400-761c-486d-ba69-9e83c0a0d981', 'OAiedeBKTKKUnLvFKY');

INSERT INTO business_client (id, user_id, business_id, created_at) VALUES ('63a1fe07-add3-41cf-a889-c75ead2d6975', '59390cb6-203a-408e-93f2-4f1efbdfe5ef', 'a092db50-8447-4f5e-bf12-2743ba9211e6', '2025-09-17 10:38:15');
INSERT INTO business_client (id, user_id, business_id, created_at) VALUES ('698666f0-af69-4155-b968-7a0960ae78e8', 'dd6d6340-d919-46f7-b999-5b24be7627ff', '6c29382c-9aa6-4aff-8fe4-f7c21c4d692d', '2024-08-18 04:28:34');

INSERT INTO barbershop_client_profile (business_client_id, picture, comment, money_generated, like_to_come) VALUES ('63a1fe07-add3-41cf-a889-c75ead2d6975', 'rvWrrFvwPSpqgMj', 'pWplxjVHBYEXzaet', 2329, '11:43:33');
INSERT INTO barbershop_client_profile (business_client_id, picture, comment, money_generated, like_to_come) VALUES ('698666f0-af69-4155-b968-7a0960ae78e8', 'bcmLjyRFk', 'aFiTWiuqh', 1620, '11:15:30');

INSERT INTO business_subscription (id, business_id, plan_id, billing_period, payer_user_id, status, current_period_start, current_period_end, auto_renew, provider, created_at, updated_at) VALUES ('e95b220f-c43b-4a12-8b34-bb98004ab15c', 'a092db50-8447-4f5e-bf12-2743ba9211e6', '40985e49-2c6b-42ff-b007-ae08706a5905', 'MONTHLY', 'dd6d6340-d919-46f7-b999-5b24be7627ff', 'PAST_DUE', '2024-04-29 22:57:06', '2025-05-04 00:52:46', TRUE, 'esiKkQvgAKRROZUaRq', '2025-06-25 16:50:34', '2025-09-22 02:12:30');
INSERT INTO business_subscription (id, business_id, plan_id, billing_period, payer_user_id, status, current_period_start, current_period_end, auto_renew, provider, created_at, updated_at) VALUES ('d5b1941e-9672-4548-a197-f941f864f697', '6c29382c-9aa6-4aff-8fe4-f7c21c4d692d', '6f28d316-7a4a-4360-aceb-fdd5c5b64254', 'YEARLY', '59390cb6-203a-408e-93f2-4f1efbdfe5ef', 'CANCELED', '2024-02-29 22:21:21', '2025-01-03 08:31:44', FALSE, 'PrtDltuwYv', '2024-04-15 05:07:34', '2025-04-28 02:07:48');

INSERT INTO client_service_variant (id, business_client_id, service_id, name_of_service, photo, notes, average_duration_minutes, is_active, created_at, updated_at) VALUES ('a3ff50e1-d0a1-4ae6-a2fd-225d0e8eb14e', '698666f0-af69-4155-b968-7a0960ae78e8', '2b7cbac4-917e-47bf-86d0-32a20c4d8249', 'zTDkesLfpJdgle', 'cmxergTscluEZqtLg', 'JXXejxOOvDuKQ', 3884, FALSE, '2024-03-07 16:23:47', '2025-03-15 12:40:23');
INSERT INTO client_service_variant (id, business_client_id, service_id, name_of_service, photo, notes, average_duration_minutes, is_active, created_at, updated_at) VALUES ('138e80e0-adb6-417e-bc82-07cffd4e2745', '698666f0-af69-4155-b968-7a0960ae78e8', '2b7cbac4-917e-47bf-86d0-32a20c4d8249', 'oWDElcxWEKvOvxO', 'qFxfIZVZMyshSHVbT', 'QMIxqZTTTWhfGrEpZ', 3939, TRUE, '2024-08-24 03:53:25', '2025-03-03 07:18:12');

INSERT INTO payment (id, subscription_id, business_id, payer_user_id, period_start, period_end, base_price_cents, adjustment_amount_cents, final_price_cents, currency, status, paid_at, provider_payment_id, created_at) VALUES ('ec65f6cb-8ebf-4e35-a4ff-5c1bf09a9ca8', 'd5b1941e-9672-4548-a197-f941f864f697', '6c29382c-9aa6-4aff-8fe4-f7c21c4d692d', NULL, '2025-10-31 09:57:01', '2025-04-28 17:54:15', 4744, 4182, 844, 'bXwpraxRmOaakab', 'PAID', '2024-08-09 02:41:14', 'wqbHxpcTWTkHuKZfW', '2025-11-24 04:01:29');
INSERT INTO payment (id, subscription_id, business_id, payer_user_id, period_start, period_end, base_price_cents, adjustment_amount_cents, final_price_cents, currency, status, paid_at, provider_payment_id, created_at) VALUES ('97300af2-b593-4b55-baa1-3a5fb2300b99', NULL, 'a092db50-8447-4f5e-bf12-2743ba9211e6', '59390cb6-203a-408e-93f2-4f1efbdfe5ef', '2025-01-06 12:09:50', '2024-09-18 04:31:25', 3565, 1384, 1496, 'OicWaCQHsmSW', 'PAID', NULL, 'dSCsxiQCtTGyDndltz', '2024-06-28 00:59:13');

INSERT INTO payment_adjustment_applied (payment_id, rule_id, type, value, amount_cents) VALUES ('97300af2-b593-4b55-baa1-3a5fb2300b99', 'c1cbe7f6-efd6-4158-90d2-5824f8137a6b', 'PERCENT_DISCOUNT', 633, 743);
INSERT INTO payment_adjustment_applied (payment_id, rule_id, type, value, amount_cents) VALUES ('97300af2-b593-4b55-baa1-3a5fb2300b99', 'e0363049-a6e1-44b3-af1c-0ec63f4cc9f2', 'AMOUNT_DISCOUNT', 4869, 1159);

INSERT INTO review (id, business_id, rating, comment, user_id, updated_at, created_at, status) VALUES ('45b1ff16-05e9-419f-8bee-1011de2ca934', '6c29382c-9aa6-4aff-8fe4-f7c21c4d692d', 3525, 'xmDuoztv', '59390cb6-203a-408e-93f2-4f1efbdfe5ef', '2025-10-20 03:38:15', '2025-11-21 08:52:16', 'TYXQvAChlkVvkd');
INSERT INTO review (id, business_id, rating, comment, user_id, updated_at, created_at, status) VALUES ('47513afe-adef-4882-b8b9-7fc9bdaf7b89', '6c29382c-9aa6-4aff-8fe4-f7c21c4d692d', 76, 'suyJARRUfw', '59390cb6-203a-408e-93f2-4f1efbdfe5ef', '2025-04-12 12:26:26', '2025-12-14 16:29:26', 'zhHVBhwyzWBgXp');

INSERT INTO worker (id, role, user_id, business_id, is_working, created_at, picture) VALUES ('b149e166-8d7c-435c-9016-8668cd770731', 'ADMIN', '59390cb6-203a-408e-93f2-4f1efbdfe5ef', 'a092db50-8447-4f5e-bf12-2743ba9211e6', TRUE, '2025-01-24 22:14:12', 'SzJzmRpttE');
INSERT INTO worker (id, role, user_id, business_id, is_working, created_at, picture) VALUES ('d050516d-8409-4456-ac69-4187d845d3f8', 'OWNER', '59390cb6-203a-408e-93f2-4f1efbdfe5ef', '6c29382c-9aa6-4aff-8fe4-f7c21c4d692d', TRUE, '2024-11-18 19:46:49', NULL);

INSERT INTO visit (id, business_id, business_client_id, worker_id, started_at, end_at, status, note, created_at, updated_at) VALUES ('76f2cdde-918c-4102-b8cb-df1f30fb4bbe', '6c29382c-9aa6-4aff-8fe4-f7c21c4d692d', '63a1fe07-add3-41cf-a889-c75ead2d6975', 'b149e166-8d7c-435c-9016-8668cd770731', NULL, '2024-11-17 12:31:32', 'PENDING', 'LfErNZaONDBs', '2026-01-12 16:33:45', '2024-03-24 06:43:58');
INSERT INTO visit (id, business_id, business_client_id, worker_id, started_at, end_at, status, note, created_at, updated_at) VALUES ('f6d5679f-cd54-4816-bccb-2a50d8cbcccc', '6c29382c-9aa6-4aff-8fe4-f7c21c4d692d', '63a1fe07-add3-41cf-a889-c75ead2d6975', 'b149e166-8d7c-435c-9016-8668cd770731', '2024-12-23 00:48:59', '2025-03-26 04:08:45', 'CONFIRMED', 'RLkLpuxd', '2025-04-30 08:27:24', '2025-09-16 16:14:46');

INSERT INTO visit_service_item (id, visit_id, service_id, client_service_variant_id, note, started_at, end_at, price_snapshot, real_duration_of_service) VALUES ('971b6350-a560-4a2a-9643-deb2b7bc342f', '76f2cdde-918c-4102-b8cb-df1f30fb4bbe', '2b7cbac4-917e-47bf-86d0-32a20c4d8249', NULL, 'hHLBJErQK', '17:54:41', '10:39:09', 4502, 334);
INSERT INTO visit_service_item (id, visit_id, service_id, client_service_variant_id, note, started_at, end_at, price_snapshot, real_duration_of_service) VALUES ('02180ebf-448f-405d-b604-59194c38e7eb', 'f6d5679f-cd54-4816-bccb-2a50d8cbcccc', '2b7cbac4-917e-47bf-86d0-32a20c4d8249', '138e80e0-adb6-417e-bc82-07cffd4e2745', 'yDnaTSqQ', '07:55:58', '05:07:58', 4816, 2921);

INSERT INTO worker_availability (id, worker_id, business_id, type, weekday, date, start_time, end_time, created_at) VALUES ('6e24ee18-25ac-4f3b-b0f1-ccd92439227c', 'b149e166-8d7c-435c-9016-8668cd770731', 'a092db50-8447-4f5e-bf12-2743ba9211e6', 'ONE_OFF_SHIFT', 'SAT', '2021-12-04', '20:57:48', '00:53:26', '2025-06-02 17:13:35');
INSERT INTO worker_availability (id, worker_id, business_id, type, weekday, date, start_time, end_time, created_at) VALUES ('ef004407-b29d-4395-b56c-c82d2692b80b', 'b149e166-8d7c-435c-9016-8668cd770731', 'a092db50-8447-4f5e-bf12-2743ba9211e6', 'WEEKLY_TEMPLATE', NULL, '2021-07-26', '18:59:02', '11:31:53', '2025-09-14 01:01:52');

INSERT INTO worker_service (id, worker_id, service_id, is_enabled, created_at) VALUES ('5538d0c0-703c-4308-a28e-48f487b9c816', 'b149e166-8d7c-435c-9016-8668cd770731', '2b7cbac4-917e-47bf-86d0-32a20c4d8249', TRUE, '2024-12-11 20:38:02');
INSERT INTO worker_service (id, worker_id, service_id, is_enabled, created_at) VALUES ('75bfecab-ecff-4449-ab71-6c3f1dc79fc2', 'b149e166-8d7c-435c-9016-8668cd770731', '2886d3af-3349-429f-b5ad-8d47a202f873', TRUE, '2024-03-18 20:41:13');

