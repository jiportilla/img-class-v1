# Make targets for building the Image recognition API with Go and Tensorflow edge service

# This imports the variables from horizon/hzn.json. You can ignore these lines, but do not remove them.
-include horizon/.hzn.json.tmp.mk

# Default ARCH to the architecture of this machines (as horizon/golang describes it)
export ARCH ?= $(shell hzn architecture)

# Build the docker image for the current architecture
build-lab1:
	docker build -t $(DOCKER_IMAGE_BASE)_$(ARCH):$(SERVICE_VERSION) -f ./Dockerfile.$(ARCH).lab1 .
build-lab2:
	docker build -t $(DOCKER_IMAGE_BASE)_$(ARCH):$(SERVICE_VERSION) -f ./Dockerfile.$(ARCH).lab2 .


# Publish the service to the Horizon Exchange for the current architecture
publish-service:
	hzn exchange service publish -f horizon/service.definition.json

# Publish the pattern to the Horizon Exchange for the current architecture
publish-pattern:
	hzn exchange pattern publish -f horizon/pattern.json

# Register Register this edge node with Horizon with pattern
register-pattern:
	hzn register -p pattern-img-class-amd64 	

# Unregister this edge node from Horizon
unregister:
	hzn unregister -fD

# new testing method
run:
#	hzn dev service start -S
	@echo 'Testing service...'
	docker run -p 8080:8080 --rm iportilla/img-recognition
	@echo 'run make test-image'

# Test image recognition API
test-lab1:
	curl localhost:8080/recognize -F 'image=@./images/two.png' | jq

test-lab2:
	curl localhost:8080/recognize -F 'image=@./images/cat.jpeg' | jq

# Publish an object in the Horizon Model Management Service 
publish-label:
	hzn mms object publish -m mms/label.object.json -f mms/imagenet_comp_graph_label_strings.txt 

publish-graph:
	hzn mms object publish -m mms/graph.object.json -f mms/tensorflow_inception_graph.pb 

publish-zip:
	hzn mms object publish -m mms/zip.object.json -f mms/inception5h.zip -v

publish-digits:
	hzn mms object publish -m mms/digits.object.json -f mms/digits_comp_graph_label_strings.txt

#List objects in the Horizon Model Management Service
list-label:
	hzn mms object list -t txt -i imagenet_comp_graph_label_strings.txt -d

list-graph:
	hzn mms object list -t bin -i tensorflow_inception_graph.pb -d

list-zip:
	hzn mms object list -t zip -i inception5h.zip -d

list-digits:
	hzn mms object list -t csv -i digits_comp_graph_label_strings.txt -d
list-files:
	sudo ls -Rla /var/horizon/ess-store/sync/local

# Get latest model from CSS local store
get-zip:
	sudo cp /var/horizon/ess-store/sync/local/major-peacock-icp-cluster-zip-inception5h.zip model/inception5h.zip
# Delete an object in the Horizon Model Management Service
delete-graph:
	hzn mms object delete --type=bin --id=tensorflow_inception_graph.pb

delete-label:
	hzn mms object delete --type=txt --id=imagenet_comp_graph_label_strings.txt

delete-zip:
	hzn mms object delete --type=zip --id=inception5h.zip 

delete-digits:
	hzn mms object delete --type=csv --id=digits_comp_graph_label_strings.txt 

# target for script - overwrite and pull instead of push docker image
publish-service-overwrite:
	hzn exchange service publish -O -P -f horizon/service.definition.json

# Publish Service Policy target for exchange publish script
publish-service-policy:
	hzn exchange service addpolicy -f horizon/service_policy.json $(HZN_ORG_ID)/$(SERVICE_NAME)_$(SERVICE_VERSION)_$(ARCH)

# Publish Business Policy target for exchange publish script
#publish-business-policy:
#	hzn exchange business addpolicy -f horizon/business_policy.json $(HZN_ORG_ID)/$(SERVICE_NAME)_$(SERVICE_VERSION)_$(ARCH)

# new target for icp exchange to run on startup to publish only
publish-only:
	ARCH=amd64 $(MAKE) publish-service-overwrite
	ARCH=amd64 $(MAKE) publish-service-policy
	#ARCH=arm $(MAKE) publish-service-overwrite
	#ARCH=arm $(MAKE) publish-service-policy
	#ARCH=arm64 $(MAKE) publish-service-overwrite
	#ARCH=arm64 $(MAKE) publish-service-policy
	hzn exchange pattern publish -f horizon/pattern-all-arches.json

clean:
	-docker rmi $(DOCKER_IMAGE_BASE)_$(ARCH):$(SERVICE_VERSION) 2> /dev/null || :

clean-all-archs:
	ARCH=amd64 $(MAKE) clean
	#ARCH=arm $(MAKE) clean
	#ARCH=arm64 $(MAKE) clean

# This imports the variables from horizon/hzn.cfg. You can ignore these lines, but do not remove them.
horizon/.hzn.json.tmp.mk: horizon/hzn.json
	@ hzn util configconv -f $< > $@

.PHONY: build build-all-arches test publish-service build-test-publish publish-all-arches clean clean-all-archs

