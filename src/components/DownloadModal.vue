<template>
  <Teleport to="body">
    <div v-if="open" class="modal-backdrop" role="presentation" @click.self="close">
      <section
        class="download-modal card"
        role="dialog"
        aria-modal="true"
        aria-labelledby="download-title"
        aria-describedby="download-description"
      >
        <button class="close-button" type="button" aria-label="Cerrar ventana" @click="close">
          <span aria-hidden="true">&times;</span>
        </button>

        <div class="modal-icon" aria-hidden="true">&#8595;</div>
        <p class="eyebrow">Acceso anticipado</p>
        <h2 id="download-title">Descarga TerraLiam para Android</h2>
        <p id="download-description" class="intro">
          Instala la versión de prueba directamente en tu dispositivo. El archivo APK es una forma temporal de probar la app antes de su publicación en Google Play.
        </p>

        <a class="btn btn-lime download-button" :href="apkHref" download>
          Descargar APK
        </a>

        <div class="notice">
          <strong>Sobre la instalación</strong>
          <p>
            Android puede mostrar una alerta porque el archivo no procede todavía de Google Play. La alerta es una medida de seguridad del sistema y no significa por sí sola que TerraLiam sea dañino. Descarga únicamente desde esta web oficial.
          </p>
        </div>

        <ol class="steps">
          <li><strong>Descarga el APK</strong> y espera a que termine.</li>
          <li><strong>Abre el archivo</strong> desde la notificación o la carpeta Descargas.</li>
          <li><strong>Permite temporalmente</strong> la instalación desde esta fuente cuando Android lo solicite.</li>
          <li><strong>Instala TerraLiam</strong> y abre la aplicación.</li>
          <li><strong>Desactiva el permiso</strong> al terminar desde Ajustes &gt; Aplicaciones &gt; Acceso especial &gt; Instalar apps desconocidas.</li>
        </ol>

        <p class="security-note">
          Si Android muestra un aviso distinto, cancela la instalación y confirma que descargaste el archivo desde <strong>terraliam.vercel.app</strong>. Mantén Android actualizado y no compartas el APK en sitios no oficiales.
        </p>
      </section>
    </div>
  </Teleport>
</template>

<script setup>
defineProps({
  open: { type: Boolean, default: false },
  apkHref: { type: String, default: '/downloads/terraliam.apk' },
})

const emit = defineEmits(['close'])

function close() {
  emit('close')
}
</script>

<style scoped>
.modal-backdrop {
  position: fixed;
  inset: 0;
  z-index: 100;
  display: grid;
  place-items: center;
  padding: 1rem;
  background: rgba(27, 42, 74, 0.72);
}

.download-modal {
  position: relative;
  width: min(100%, 640px);
  max-height: min(90vh, 760px);
  overflow: auto;
  padding: clamp(1.4rem, 4vw, 2.4rem);
  color: var(--ink);
  background: var(--cream);
}

.close-button {
  position: absolute;
  top: 1rem;
  right: 1rem;
  width: 42px;
  height: 42px;
  border: 3px solid var(--sky-deep);
  border-radius: 50%;
  background: var(--white);
  color: var(--ink);
  font: 700 1.6rem/1 var(--font-body);
  cursor: pointer;
}

.modal-icon {
  display: grid;
  width: 52px;
  height: 52px;
  place-items: center;
  margin-bottom: 0.8rem;
  border-radius: 16px;
  background: var(--teal-deep);
  color: var(--white);
  font-size: 2rem;
}

.eyebrow {
  margin-bottom: 0.3rem;
  color: var(--teal-deep);
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

h2 {
  max-width: 26rem;
  margin-right: 2.5rem;
}

.intro {
  color: var(--muted);
  font-weight: 700;
}

.download-button {
  width: 100%;
  margin: 0.5rem 0 1.2rem;
}

.notice,
.security-note {
  padding: 0.9rem 1rem;
  border-left: 4px solid var(--gold);
  background: var(--white);
}

.notice p,
.security-note {
  margin: 0.35rem 0 0;
  color: var(--muted);
  font-size: 0.94rem;
}

.steps {
  display: grid;
  gap: 0.7rem;
  margin: 1.2rem 0;
  padding-left: 1.4rem;
}

.steps li::marker {
  color: var(--teal-deep);
  font-weight: 900;
}

@media (max-width: 520px) {
  .modal-backdrop {
    align-items: end;
    padding: 0;
  }

  .download-modal {
    max-height: 92vh;
    border-radius: 24px 24px 0 0;
  }
}
</style>