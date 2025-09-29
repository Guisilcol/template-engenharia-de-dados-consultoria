#!/usr/bin/env python3
"""
Google Cloud Run Job - Template para Consultoria de Dados
"""

import os
import sys
import logging
from datetime import datetime
from typing import Dict, Any

# Adiciona o diretório pai ao path para importar shared modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import shared.shared_module as sm
from google.cloud import logging as cloud_logging

class CloudRunJob:
    """Classe principal para o Cloud Run Job"""
    
    def __init__(self):
        """Inicializa o job com configurações de logging"""
        self.setup_logging()
        self.job_name = os.getenv('K_SERVICE', 'sample-job')
        self.project_id = os.getenv('GOOGLE_CLOUD_PROJECT', 'default-project')
        self.revision = os.getenv('K_REVISION', 'unknown')
        
    def setup_logging(self):
        """Configura logging para Cloud Logging"""
        # Se rodando no Cloud Run, usa Cloud Logging
        if os.getenv('K_SERVICE'):
            client = cloud_logging.Client()
            client.setup_logging()
        
        # Configura logging local
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)
    
    def validate_environment(self) -> bool:
        """Valida se todas as variáveis de ambiente necessárias estão definidas"""
        required_vars = ['GOOGLE_CLOUD_PROJECT']
        missing_vars = []
        
        for var in required_vars:
            if not os.getenv(var):
                missing_vars.append(var)
        
        if missing_vars:
            self.logger.error(f"Variáveis de ambiente obrigatórias não encontradas: {missing_vars}")
            return False
        
        return True
    
    def process_data(self) -> Dict[str, Any]:
        """
        Lógica principal do job - processa dados
        Substitua esta função pela sua lógica de negócio
        """
        self.logger.info("Iniciando processamento de dados...")
        
        # Exemplo de processamento usando shared module
        result = sm.some_fn()
        self.logger.info(f"Resultado do shared module: {result}")
        
        # Simula processamento de dados
        processed_data = {
            'timestamp': datetime.now().isoformat(),
            'job_name': self.job_name,
            'project_id': self.project_id,
            'revision': self.revision,
            'shared_result': result,
            'processed_records': 100,
            'status': 'success'
        }
        
        self.logger.info(f"Processamento concluído: {processed_data['processed_records']} registros")
        return processed_data
    
    def save_results(self, data: Dict[str, Any]) -> bool:
        """
        Salva os resultados do processamento
        Pode ser adaptado para BigQuery, Cloud Storage, etc.
        """
        self.logger.info("Salvando resultados...")
        
        # Aqui você implementaria a lógica de salvamento
        # Exemplo: salvar no BigQuery, Cloud Storage, etc.
        
        self.logger.info("Resultados salvos com sucesso")
        return True
    
    def run(self) -> int:
        """Executa o job principal"""
        try:
            self.logger.info(f"Iniciando job {self.job_name} no projeto {self.project_id}")
            
            # Valida ambiente
            if not self.validate_environment():
                return 1
            
            # Processa dados
            results = self.process_data()
            
            # Salva resultados
            if self.save_results(results):
                self.logger.info("Job executado com sucesso!")
                return 0
            else:
                self.logger.error("Erro ao salvar resultados")
                return 1
                
        except Exception as e:
            self.logger.error(f"Erro durante execução do job: {str(e)}", exc_info=True)
            return 1

def main():
    """Função principal"""
    job = CloudRunJob()
    exit_code = job.run()
    sys.exit(exit_code)

if __name__ == "__main__":
    main()