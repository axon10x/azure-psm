#!/bin/bash

az account list-locations --query "[][name, displayName]"