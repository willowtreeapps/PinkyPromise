LOGS_DIR = logs

.DEFAULT: usage
.PHONY: usage
usage:
	@echo "Make manages our CI server builds and provides local build options."
	@echo ""
	@echo "Local usage:"
	@echo "    make test\t\tRun PinkyPromise test suite"

.PHONY: test
test:
	make _test PROJECT=PinkyPromise \
	           SCHEME=PinkyPromise \
	           SDK=macosx10.12

.PHONY: _test
_test:
	set -o pipefail && \
	xcodebuild test -project $(PROJECT).xcodeproj -scheme $(SCHEME) -sdk $(SDK) \
		CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= 2>&1 | \
				tee $(CIRCLE_ARTIFACTS)/xcode_raw_test.log | \
				xcpretty --color --report junit --output $(CIRCLE_TEST_REPORTS)/test-results.xml
