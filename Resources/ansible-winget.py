#!/usr/bin/python
# -*- coding: utf-8 -*-
# This Ansible module manages applications via Winget on a managed Windows node

# Copyright: (c) 2024, Daniil Grigoryan
# Copyright: (c) 2024, Ansible Project
# Copyright: (c) 2024, Microsoft Inc.
# GNU General Public License v2.0 (see LICENSE or https://www.gnu.org/licenses/gpl-2.0.txt)

# This Ansible module manages applications via Winget on a managed Windows node

# This is a Ansible-Winget documentation stub. Actual code is in the .ps1 file of the same name.

ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'community'}

DOCUMENTATION = '''
---
module: ansible-winget
short_description: Manage applications via Winget on Windows nodes
description:
  - This module allows the management of applications via Winget on Windows nodes.
  - It can install, uninstall, or update applications using Winget.
  requirements:
  - Windows >= 10
  - Winget >= 1.0.0
options:
  appID:
    description:
      - The ID of the application to be managed.
    required: true
    type: str
  state:
    description:
      - The desired state of the application.
    choices: [absent, present, updated]
    required: true
    type: str
  architecture:
    description:
      - The architecture of the application.
    choices: [x64, x86, arm64]
    required: false
    type: str
  scope:
    description:
      - The scope of the application installation.
    choices: [user, machine]
    required: false
    type: str
  version:
    description:
      - The version of the application to be managed.
    required: false
    type: str
author:
  - Daniil Grigoryan
'''

EXAMPLES = '''
# Install an application
- name: Install VLC media player
  ansible-winget:
    appID: VideoLAN.VLC
    state: present
    architecture: x64
    scope: user
    version: 3.0.20

# Uninstall an application
- name: Uninstall VLC media player
  ansible-winget:
    appID: VideoLAN.VLC
    state: absent
    scope: user
    version: 3.0.20

# Update an application
- name: Update VLC media player
  ansible-winget:
    appID: VideoLAN.VLC
    state: updated
    architecture: x64
    scope: user
    version: 3.0.20
'''

RETURN = '''
changed:
  description: Whether any changes were made
  returned: always
  type: bool
  sample: true
msg:
  description: The output message from Winget
  returned: always
  type: str
  sample: "Package installed successfully"
'''
