XCODE_COMMAND=xcodebuild
XCODE_GENERIC_FLAGS=-project 'PrettyOkayKit.xcodeproj'
XCODE_IOS_FLAGS=-scheme 'PrettyOkayKit'

.PHONY: all clean docs test

all:
	$(XCODE_COMMAND) $(XCODE_GENERIC_FLAGS) $(XCODE_IOS_FLAGS) build

clean:
	$(XCODE_COMMAND) $(XCODE_GENERIC_FLAGS) $(XCODE_IOS_FLAGS) clean

docs:
	jazzy \
		--clean \
		--author "Nate Stedman" \
		--author_url "http://natestedman.com" \
		--github_url "https://github.com/natestedman/PrettyOkayKit" \
		--github-file-prefix "https://github.com/natestedman/PrettyOkayKit/tree/master" \
		--module-version "1.0" \
		--xcodebuild-arguments -scheme,PrettyOkayKit \
		--module PrettyOkayKit \
		--output Documentation \

test:
	xcodebuild $(XCODE_GENERIC_FLAGS) $(XCODE_IOS_FLAGS) test
