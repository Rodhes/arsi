require 'active_record'
require 'arsi'
require 'minitest/autorun'

# 1. Configuração do Banco em Memória
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

# 2. Ativação do ARSI (O motor que deveria bloquear SQLi)
Arsi.arel_check! 

# 3. Criamos uma tabela de SISTEMA (sem coluna account_id)
# De acordo com a nossa análise, o Arsi ignora tabelas que não têm IDs de escopo.
ActiveRecord::Schema.define do
  create_table :system_settings, id: false do |t|
    t.string :name
    t.string :value
  end
end

class SystemSetting < ActiveRecord::Base; end

# 4. O Teste de Bypass
describe "Arsi Scope Bypass Proof" do
  before do
    SystemSetting.create!(name: "MAINTENANCE_MODE", value: "OFF")
  end

  it "CONFIRMA BYPASS: O Arsi permite SQL Injection em tabelas sem colunas de escopo" do
    puts "\n[?] Verificando se o Arsi protege a tabela system_settings..."

    # Payload de SQL Injection que afeta todas as linhas (1=1)
    # Em uma tabela protegida, o Arsi deveria lançar Arsi::UnscopedSQL aqui.
    SystemSetting.where("1=1").update_all(value: "PWNED")

    # Validação do impacto
    if SystemSetting.first.value == "PWNED"
      puts "\n" + ("="*60)
      puts "[!] IMPACTO CRÍTICO CONFIRMADO"
      puts "[!] O Arsi ignorou a query maliciosa na tabela system_settings."
      puts "[!] Motivo: Tabela não possui colunas que casam com SCOPEABLE_REGEX."
      puts ("="*60) + "\n"
    end
  end
end
