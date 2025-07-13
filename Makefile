SWIFT_BIN_PATH = $(shell swift build --show-bin-path)
TEST_PACKAGE= $(SWIFT_BIN_PATH)/BreezeLambdaWebHookPackageTests.xctest
BUILD_TEMP = .build/temp

linux_test:
	docker-compose -f docker/docker-compose.yml run --rm test

linux_shell:
	docker-compose -f docker/docker-compose.yml run --rm shell

build_no_cache:
	docker-compose -f docker/docker-compose.yml build --no-cache

composer_up:
	docker-compose -f docker/docker-compose.yml up

composer_down:
	docker-compose -f docker/docker-compose.yml down

localstack:
	docker run -it --rm -p "4566:4566" localstack/localstack

test:
	swift test --enable-code-coverage

coverage:
	llvm-cov export $(TEST_PACKAGE) \
		--instr-profile=$(SWIFT_BIN_PATH)/codecov/default.profdata \
		--format=lcov > $(GITHUB_WORKSPACE)/lcov.info

preview_docc_lambda_api:
	swift package --disable-sandbox preview-documentation --target BreezeLambdaWebHook

