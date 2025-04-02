import { AndroidIcon } from '@/components/solidjs/icons/AndroidIcon'
import { WindowsIcon } from '@/components/solidjs/icons/WindowsIcon'
import { TrashIcon } from '@/components/solidjs/icons/TrashIcon'
import { DownloadIcon } from '@/components/solidjs/icons/DownloadIcon'
import type { FileEntity } from '@/types/archivos'

interface Props {
  file: FileEntity
  deleteItem: () => void
}

export const FileCard = ({ file, deleteItem }: Props) => {
  return (
    <div
      class="rounded shadow p-3 text-sm space-y-2 transition-colors border
                bg-black/20 text-gray-300 border-white/10
                hover:bg-black/30 hover:border-white/20"
    >
      <div class="flex flex-wrap gap-2">
        {file.tipo === 'apk' ? (
          <span class="bg-emerald-500/10 p-2 inline-block rounded border border-emerald-900">
            <AndroidIcon class="w-6 h-6" />
          </span>
        ) : (
          <span class="bg-cyan-500/15 p-2 inline-block rounded border border-cyan-900">
            <WindowsIcon class="w-6 h-6" />
          </span>
        )}
        <div>
          <div>
            <span class="text-gray-200 font-medium">
              {file.tipo === 'apk' ? 'Android App' : 'Aplicación de escritorio'}
            </span>
          </div>
          <div>
            <span class="text-gray-500 mr-1">Tamaño:</span>
            <span>{(Number(file.size) / (1024 * 1024)).toFixed(2)} MB</span>
          </div>
        </div>
      </div>
      <div>
        <p class="text-gray-500 block">Nombre:</p>
        <p class="overflow-hidden overflow-ellipsis">{file.nombre}</p>
      </div>
      <div>
        <p class="text-gray-500 block">Archivo:</p>
        <p class="overflow-hidden overflow-ellipsis">{file.filename}</p>
      </div>
      <div>
        <p class="text-gray-500 block">Subido:</p>
        <p class="overflow-hidden overflow-ellipsis">
          {new Date(file.fechaCreacion).toLocaleString()}
        </p>
      </div>
      <div>
        <p class="text-gray-500 block">Autor:</p>
        <p>{file.user.nombre}</p>
      </div>
      <div>
        <p class="text-gray-500 mr-1">Visible para todos:</p>
        <p>{file.visible ? 'Si' : 'No'}</p>
      </div>
      <div class="flex flex-wrap gap-2 justify-end">
        <button
          class="border border-white/10 p-1.5 rounded text-gray-400
            hover:bg-white/10 hover:text-white
            transition-colors"
          onclick={() => {
            deleteItem()
          }}
        >
          <TrashIcon class="w-5 h-5" />
        </button>
        <button
          class="border border-white/10 p-1.5 rounded text-gray-400
            hover:bg-white/10 hover:text-white
            transition-colors"
        >
          <DownloadIcon class="w-5 h-5" />
        </button>
      </div>
    </div>
  )
}
