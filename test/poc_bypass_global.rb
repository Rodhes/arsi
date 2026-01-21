require "active_record"
require "arsi"
require "minitest/autorun"

# Setup do Banco de Dados em Memória
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

# Criando uma tabela GLOBAL (sem account_id) - O ALVO DO BYPASS
ActiveRecord::Schema.define do
  create_table :system_settings, force: true do |t|
    t.string :key
    t.string :value
  end
end

class SystemSetting < ActiveRecord::Base; end

describe "Arsi Scope Bypass Proof" do
  it "CONFIRMA BYPASS: O Arsi permite SQL Injection em tabelas globais" do
    SystemSetting.create!(key: "maintenance_mode", value: "false")
    
    puts "\n[?] Verificando se o Arsi protege a tabela system_settings..."
    
    # Ativando o Arsi
    Arsi.arel_check! do
      # Esta query deveria ser bloqueada ou filtrada, mas o Arsi a ignora 
      # porque a tabela não tem colunas que casam com a SCOPEABLE_REGEX
      SystemSetting.update_all("value = 'HACKED'")
    end

    if SystemSetting.first.value == "HACKED"
      puts "\n============================================================"
      puts "[!] IMPACTO CRÍTICO CONFIRMADO"
      puts "[!] O Arsi ignorou a query maliciosa na tabela system_settings."
      puts "[!] Motivo: Tabela nao possui colunas que casam com SCOPEABLE_REGEX."
      puts "============================================================\n"
    else
      raise "Falha no PoC: O Arsi bloqueou a query inesperadamente."
    end
  end
end
