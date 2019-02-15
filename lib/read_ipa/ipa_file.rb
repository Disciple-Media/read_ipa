require 'zip'
require 'read_ipa/plist_binary'
require 'cfpropertylist'

module ReadIpa
  class IpaFile
    attr_accessor :plist, :file_path
    def initialize(file_path)
      self.file_path = file_path
      @app_folder = get_app_folder
      @zipfile = Zip::File.open(file_path)
      plist_str = @zipfile.read(@app_folder + 'Info.plist')
      @info_plist = InfoPlist.new(plist_str)

      cf_plist = CFPropertyList::List.new(data: plist_str, format: CFPropertyList::List::FORMAT_AUTO)
      self.plist = cf_plist.value.to_rb
    end

    def version
      @info_plist.version
    end

    def short_version
      @info_plist.short_version
    end

    def name
      @info_plist.name
    end

    def target_os_version
      @info_plist.target_os_version
    end

    def minimum_os_version
      @info_plist.minimum_os_version
    end

    def url_schemes
      @info_plist.url_schemes
    end

    def icon_file
      get_highest_res_icon(@info_plist.icon_files)
    end

    def executable_file_name
      @info_plist.executable_file_name
    end

    def executable_file
      read_file(executable_file_name)
    end

    def get_app_folder
      plist_path = nil
      Zip::File.foreach(file_path) do |entry|
        if /.*\.app\/Info\.plist$/ =~ entry.to_s
          plist_path = entry
          break
        end
      end
      app_folder = plist_path.to_s.gsub(/Info\.plist$/, '')
      raise "Could not identify Main app Folder" if app_folder.nil?
      app_folder
    end

    def mobile_provision_file
      read_file("embedded.mobileprovision")
    end

    def bundle_identifier
      @info_plist.bundle_identifier
    end

    def icon_prerendered
      @info_plist.icon_prerendered
    end

    def for_ipad?
      @info_plist.for_ipad?
    end

    def for_iphone?
      @info_plist.for_iphone?
    end

    def find_existing_path(icon_path)
      without_extension = icon_path.gsub(/\.png$/i, '')
      regex = /#{Regexp.quote(@app_folder)}#{Regexp.quote(without_extension)}[(\.png)@~]/
      @zipfile.entries.find{|e| e.name =~ regex}
    end

    private

    def read_file(entry)
      @zipfile.read(@app_folder + entry)
    end
  end
end
