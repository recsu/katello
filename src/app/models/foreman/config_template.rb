#
# Copyright 2012 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

class Foreman::ConfigTemplate < Resources::ForemanModel

  attributes :name, :template, :snippet, :audit_comment, :template_kind_id

  def json_default_options
    { :only => [:name, :template, :snippet, :audit_comment, :template_kind_id] }
  end

  validates :name, :presence => true

  def self.revision(audit_id)
    resource.revision({:version => audit_id}, foreman_header).first
  end

  def self.build_pxe_default
    resource.build_pxe_default(foreman_header).first
  end
end