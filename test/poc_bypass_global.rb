# 1. ORDEM CRÍTICA: Logger deve vir antes de ActiveRecord
require "logger"
require "securerandom"

begin
  require "active_record"
  require "sqlite3"
  require "arsi"
  require "minitest/autorun"
rescue LoadError => e
  puts "❌ Erro ao carregar dependências: #{e.message}"
  puts "Execute: bundle install"
  exit 1
end

# Debug para conferência no log
puts "─" * 40
puts "[ENV] Ruby: #{RUBY_VERSION}"
puts "[ENV] ActiveRecord: #{ActiveRecord::VERSION::STRING}"
puts "─" * 40

# Configuração do Banco em Memória
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(nil)

# Patch necessário para o Arsi funcionar no adapter SQLite3
class ActiveRecord::ConnectionAdapters::SQLite3Adapter
  attr_accessor :arsi_relation
end

# Definição do Schema (Híbrido para evitar erros de metadados)
ActiveRecord::Schema.define do
  unless connection.table_exists?(:ar_internal_metadata)
    create_table :ar_internal_metadata, id: false do |t|
      t.string :key, primary_key: true
      t.string :value
      t.timestamps
    end
  end

  create_table :system_configs, force: true do |t|
    t.string :key
    t.string :value
    t.timestamps
  end
end

class SystemConfig < ActiveRecord::Base; end

# Suíte de Teste
describe "Arsi Bypass PoC" do
  it "confirma que without_arsi desativa as travas de segurança" do
    SystemConfig.create!(key: "admin_mode", value: "secure")

    # A gem Arsi deveria bloquear este comando por não ter .where()
    # O .without_arsi é o bypass que queremos provar
    SystemConfig.without_arsi.update_all(value: "VULNERABLE")

    assert_equal "VULNERABLE", SystemConfig.first.value

    puts "\n" + "═" * 70
    puts "🎯 DESIGN FLAW CONFIRMADO"
    puts "O Arsi foi ignorado com sucesso usando .without_arsi"
    puts "═" * 70 + "\n"
  end
end
