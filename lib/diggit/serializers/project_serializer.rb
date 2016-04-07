require 'active_model_serializers'

module Diggit
  module Serializers
    class ProjectSerializer < ActiveModel::Serializer
      attributes :gh_path, :watch
    end
  end
end
